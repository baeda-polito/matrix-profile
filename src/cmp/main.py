# import from default libraries and packages
import datetime  # data
import os
from statistics import mean

# import matplotlib.pyplot as plt  # plots
import numpy as np  # general data manipulation
import pandas as pd  # dataframe handling
import plotly.express as px
from matplotlib import dates as mdates
# import scipy.stats as stats
from scipy.stats import zscore

from src.cmp.anomaly_detection_functions import anomaly_detection, extract_vector_ad_temperature, \
    extract_vector_ad_energy, extract_vector_ad_cmp
# import from the local module distancematrix
from src.distancematrix.calculator import AnytimeCalculator
# from src.distancematrix.consumer import ContextualMatrixProfile
from src.distancematrix.consumer.contextmanager import GeneralStaticManager
from src.distancematrix.consumer.contextual_matrix_profile import ContextualMatrixProfile
from src.distancematrix.generator.euclidean import Euclidean
# from src.distancematrix.generator import Euclidean
# import from custom modules useful functions
from utils import hour_to_dec, dec_to_hour, nan_diag, dec_to_obs, ensure_dir, load_data, save_report

if __name__ == '__main__':
    # define a begin time to evaluate execution time & performance of algorithm
    begin_time = datetime.datetime.now()

    # The context is a dict defining parameters for report generation
    context = {
        'title': 'Anomaly detection report',
        'subtitle': f'Generated on {begin_time.strftime("%Y-%m-%d %H:%M:%S")}',
        'sections': [],
        'footer_text': '© 2024 Roberto Chiosa'
    }

    # Path to folders
    path_to_data = os.path.join('data')
    path_to_figures = os.path.join('results', 'figures')
    path_to_reports = os.path.join('results', 'reports')

    # from global variables load todo: simplify the wau global variables are defined
    global_variables = pd.read_csv(os.path.join(path_to_data, "global_variables.csv"), header=0)
    color_palette = 'viridis'
    dpi_resolution = 300
    fontsize = 10
    line_style_context = '-'
    line_style_other = ':'
    line_color_context = '#D83C3B'
    line_color_other = '#D5D5E0'
    line_size = 1

    ########################################################################################
    electrical_load = 'Total_Power'
    data = load_data(electrical_load)

    obs_per_day = 96  # [observation/day]
    obs_per_hour = 4  # [observation/hour]

    # print dataset main characteristics
    summary = f'\n*********************\n' \
              f'DATASET: Electrical Load dataset from {electrical_load}\n' \
              f'- From\t{data.index[0]}\n' \
              f'- To\t{data.index[len(data) - 1]}\n' \
              f'- {len(data.index[::obs_per_day])}\tdays\n' \
              f'- 1 \tobservations every 15 min\n' \
              f'- {obs_per_day}\tobservations per day\n' \
              f'- {obs_per_hour}\tobservations per hour\n' \
              f'- {len(data)}observations'

    # Visualise the data  with plotly line plot
    fig = px.line(data, title='Life expectancy in Canada')
    fig.update_layout(paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)')
    context['sections'].append({
        "title": "Dataset Summary",
        "content": summary,
        "plot": fig.to_html(full_html=False)
    })

    ########################################################################################
    # Define configuration for the Contextual Matrix Profile calculation.

    # The number of time window has been selected from CART on total electrical power,
    # results are contained in 'time_window.csv' file
    df_time_window = pd.read_csv(os.path.join(path_to_data, "time_window_corrected.csv"))

    # The context is defined as 1 hour before time window, to be consistent with other analysis,
    # results are loaded from 'm_context.csv' file
    m_context = pd.read_csv(os.path.join(path_to_data, "m_context.csv"))["m_context"][0]

    # Define output files as dataframe
    # - df_anomaly_results -> in this file the anomaly results will be saved
    # - df_contexts -> the name and descriptions of contexts
    df_anomaly_results = pd.DataFrame()
    df_contexts = pd.DataFrame(
        columns=["from", "to", "context_string", "context_string_small", "duration", "observations"])

    # begin for loop on the number of time windows
    for id_tw in range(len(df_time_window)):

        ########################################################################################
        # Data Driven Context Definition
        if id_tw == 0:
            # manually define context if it is the beginning
            context_start = 0  # [hours] i.e., 00:00
            context_end = context_start + m_context  # [hours] i.e., 01:00
            # [observations] = ([hour]-[hour])*[observations/hour]
            # m = int((hour_to_dec(df_time_window["to"][id_tw]) - 0.25 - m_context) * obs_per_hour)
            m = 23
        else:
            m = df_time_window["observations"][id_tw]  # [observations]
            context_end = hour_to_dec(df_time_window["from"][id_tw]) + 0.25  # [hours]
            context_start = context_end - m_context  # [hours]

        '''
        # 2) User Defined Context
        # We want to find all the subsequences that start from 00:00 to 02:00 (2 hours) and covers the whole day
        # In order to avoid overlapping we define the window length as the whole day of
        observation minus the context length.

        # - Beginning of the context 00:00 AM [hours]
        context_start = 17

        # - End of the context 02:00 AM [hours]
        context_end = 19

        # - Context time window length 2 [hours]
        m_context = context_end - context_start  # 2

        # - Time window length [observations]
        # m = 96 [observations] - 4 [observation/hour] * 2 [hours] = 88 [observations] = 22 [hours]
        # m = obs_per_day - obs_per_hour * m_context
        m = 20 # with guess
        '''

        # print string to explain the created context in an intelligible way
        context_string = 'Subsequences of {} h (m = {}) that start in [{},{})'.format(
            dec_to_hour(m / obs_per_hour),
            m,
            dec_to_hour(context_start),
            dec_to_hour(context_end)
        )

        # contracted context string for names
        context_string_small = 'ctx_from{}_to{}_m{}'.format(
            dec_to_hour(context_start),
            dec_to_hour(context_end),
            dec_to_hour(m / obs_per_hour)
        ).replace(":", "_")

        # update context dataframe
        df_contexts.loc[id_tw] = [
            dec_to_hour(context_start),  # "from"
            dec_to_hour(context_end),  # "to"
            context_string,  # "context_string"
            context_string_small,  # "context_string_small"
            str(m_context) + " h",  # "duration"
            m_context * obs_per_hour  # "observations"
        ]

        print('\n*********************\n',
              'CONTEXT ' + str(id_tw + 1) + ' : ' + context_string + " (" + context_string_small + ")")

        # if figures directory doesnt exists create and save into it
        ensure_dir(os.path.join(path_to_figures, context_string_small))

        '''
        # Context Definition:
        # example FROM 00:00 to 02:00
        # - m_context = 2 [hours]
        # - obs_per_hour = 4 [observations/hour]
        # - context_start = 0 [hours]
        # - context_end = context_start + m_context = 0 [hours] + 2 [hours] = 2 [hours]
        contexts = GeneralStaticManager([
            range(
                # FROM  [observations]  = x * 96 [observations] + 0 [hour] * 4 [observation/hour]
                (x * obs_per_day) + context_start * obs_per_hour,
                # TO    [observations]  = x * 96 [observations] + (0 [hour] + 2 [hour]) * 4 [observation/hour]
                (x * obs_per_day) + (context_start + m_context) * obs_per_hour)
            for x in range(len(data) // obs_per_day)
        ])
        '''
        # Context Definition:
        contexts = GeneralStaticManager([
            range(
                # FROM  [observations]  = x * 96 [observations] + 0 [hour] * 4 [observation/hour]
                ((x * obs_per_day) + dec_to_obs(context_start, obs_per_hour)),
                # TO    [observations]  = x * 96 [observations] + (0 [hour] + 2 [hour]) * 4 [observation/hour]
                ((x * obs_per_day) + dec_to_obs(context_end, obs_per_hour)))
            for x in range(len(data) // obs_per_day)
        ])

        ########################################################################################
        # Calculate Contextual Matrix Profile
        calc = AnytimeCalculator(m, data['value'].values)

        # Add generator Not Normalized Euclidean Distance
        distance_string = 'Not Normalized Euclidean Distance'
        calc.add_generator(0, Euclidean())

        # We want to calculate CMP initialize element
        cmp = calc.add_consumer([0], ContextualMatrixProfile(contexts))

        # Calculate Contextual Matrix Profile (CMP)
        calc.calculate_columns(print_progress=True)
        print("\n")

        # if data directory doesnt exists create and save into it
        ensure_dir(os.path.join(path_to_data, context_string_small))

        # Save CMP for R plot (use to_csv)
        np.savetxt(os.path.join(path_to_data, context_string_small, 'plot_cmp_full.csv'),
                   nan_diag(cmp.distance_matrix),
                   delimiter=",")

        # Save CMP for R plot (use to_csv)
        np.savetxt(os.path.join(path_to_data, context_string_small, 'match_index_query.csv'),
                   cmp.match_index_query,
                   delimiter=",")

        # Save CMP for R plot (use to_csv)
        np.savetxt(os.path.join(path_to_data, context_string_small, 'match_index_series.csv'),
                   cmp.match_index_series,
                   delimiter=",")

        # calculate the date labels to define the extent of figure
        date_labels = mdates.date2num(data.index[::m].values)

        fig = px.imshow(cmp.distance_matrix)
        fig.update_layout(paper_bgcolor='rgba(0,0,0,0)', plot_bgcolor='rgba(0,0,0,0)')
        context['sections'].append({
            "title": "Context " + str(id_tw + 1),
            "content": fig.to_html(full_html=False),
            "plot": None
        })

        save_report(context)

        ########################################################################################
        # Load Cluster results as boolean dataframe: each column represents a group
        group_df = pd.read_csv(os.path.join(path_to_data, "group_cluster.csv"), index_col='timestamp', parse_dates=True)
        # initialize dataframe of results for context to be appended to the overall result
        df_anomaly_context = group_df.astype(int)

        # set labels
        day_labels = data.index[::obs_per_day]
        # get number of groups
        n_group = group_df.shape[1]

        # perform analysis of context on groups (clusters)
        for id_cluster in range(n_group):
            # create this dataframe where dates cluster and anomalies scores will be saved
            df_result_context_cluster = pd.DataFrame()

            # time when computation starts
            begin_time_group = datetime.datetime.now()

            # get group name from dataframe
            group_name = group_df.columns[id_cluster]

            # add column of context of group in df_output
            df_anomaly_context[group_name + "." + context_string_small] = [0 for id_cluster in
                                                                           range(len(df_anomaly_context))]

            # create empty group vector
            group = np.array(group_df.T)[id_cluster]
            # get cmp from previously computed cmp
            group_cmp = cmp.distance_matrix[:, group][group, :]
            # substitute inf with zeros
            group_cmp[group_cmp == np.inf] = 0
            # get dates
            group_dates = data.index[::obs_per_day].values[group]

            # save group CMP for R plot
            np.savetxt(os.path.join(path_to_data, context_string_small, f'plot_cmp_{group_name}.csv'),
                       nan_diag(group_cmp), delimiter=",")

            # Save CMP for R plot (use to_csv)
            np.savetxt(os.path.join(path_to_data, context_string_small, f'match_index_query_{group_name}.csv'),
                       cmp.match_index_query[:, group][group, :], delimiter=",")

            # Save CMP for R plot (use to_csv)
            np.savetxt(os.path.join(path_to_data, context_string_small, f'match_index_series_{group_name}.csv'),
                       cmp.match_index_series[:, group][group, :], delimiter=",")

            # # plot CMP as matrix
            # plt.figure(figsize=(7, 7))
            # CMP_plot(contextual_mp=group_cmp,
            #          palette=color_palette,
            #          title="Power CMP (" + group_name + " only)",
            #          xlabel=group_name + " Index",
            #          legend_label=distance_string
            #          )
            # path_to_figure_cluster = os.path.join(path_to_figures, context_string_small, group_name)
            # if not path_to_figure_cluster:
            #     os.makedirs(path_to_figure_cluster)
            #
            # plt.savefig(os.path.join(path_to_figure_cluster, "polito_cmp.png"),
            #             dpi=dpi_resolution,
            #             bbox_inches='tight')
            # plt.close()

            #######################################

            # add date to df_result_context_cluster
            df_result_context_cluster["Date"] = group_df.index
            df_result_context_cluster["cluster"] = group

            # calculate the vector to be used for the anomaly detection
            vector_ad_cmp = extract_vector_ad_cmp(group_cmp=group_cmp)

            vector_ad_energy = extract_vector_ad_energy(
                group=group,
                data_full=data,
                tw=df_time_window,
                tw_id=id_tw)

            vector_ad_temperature = extract_vector_ad_temperature(
                group=group,
                data_full=data,
                tw=df_time_window,
                tw_id=id_tw)

            # calculate anomaly score though majority voting
            cmp_ad_score = anomaly_detection(
                group=group,
                vector_ad=vector_ad_cmp)

            energy_ad_score = anomaly_detection(
                group=group,
                vector_ad=vector_ad_energy)

            temperature_ad_score = anomaly_detection(
                group=group,
                vector_ad=vector_ad_temperature)

            # temperature_ad_score = stats.zscore(vector_ad_temperature)

            # add anomaly score to df_result_context_cluster
            df_result_context_cluster["cmp_score"] = cmp_ad_score
            df_result_context_cluster["energy_score"] = energy_ad_score
            df_result_context_cluster["temperature_score"] = temperature_ad_score

            # add categorization depending on some criteria
            # set to nan if severity 0/1/2 (no anomaly or not severe)
            # cmp_ad_score = np.where(cmp_ad_score == 0, np.nan, cmp_ad_score)
            # override definition of cmp_ad_score with this new definition
            # todo: when everything works fine change the variable cmp_ad_score to avoid misunderstandings
            cmp_ad_score = np.array(df_result_context_cluster["cmp_score"] + df_result_context_cluster["energy_score"])

            cmp_ad_score = np.where(cmp_ad_score < 6, np.nan, cmp_ad_score)

            # the number of anomalies is the number of non nan elements, count
            num_anomalies_to_show = np.count_nonzero(~np.isnan(cmp_ad_score))

            # only visualize if some anomaly are shown
            if num_anomalies_to_show > 0:

                # limit the number of anomalies
                if num_anomalies_to_show > 10:
                    num_anomalies_to_show = 10

                # Ordering of all days, from most to least anomalous in order of severity
                ad_order = np.argsort(cmp_ad_score)[::-1]

                # move na at the end of the vector
                ad_order = np.roll(ad_order, -np.count_nonzero(np.isnan(cmp_ad_score)))

                # create a vector to plot correctly the graph
                cmp_ad_score_plot = cmp_ad_score[ad_order][0:num_anomalies_to_show]

                '''
                # Visualise the top anomalies according to the CMP
                fig, ax = plt.subplots(num_anomalies_to_show, 2,
                                       sharex='all',
                                       # sharey='all',
                                       figsize=(8, 14 / 8 * num_anomalies_to_show),
                                       # gridspec_kw={'wspace': 0., 'hspace': 0.}
                                       )
                fig.suptitle("Anomaly Detection " + group_name.replace("_", " "))

                for j in range(0, num_anomalies_to_show):
                    anomaly_index = ad_order[j]
                    anomaly_range = range(obs_per_day * anomaly_index, obs_per_day * (anomaly_index + 1))
                    date = day_labels[anomaly_index]

                    # update output dataframe and add severity
                    df_anomaly_context.loc[df_anomaly_context.index.values == np.datetime64(date),
                                           group_name + "." + context_string_small] = cmp_ad_score[anomaly_index]

                    # dataframe for group power and energy
                    power_group = data["value"].values.reshape((-1, obs_per_day))[group].T
                    energy_group = np.empty((power_group.shape[0], power_group.shape[1]))
                    for k in range(0, power_group.shape[1]):
                        energy_group[:, k] = np.cumsum(power_group[:, k])

                    # dataframe for group power and energy for anomaly
                    power_group_anomaly = data["value"].values[anomaly_range]
                    energy_group_anomaly = np.cumsum(power_group_anomaly)

                    if num_anomalies_to_show == 1:
                        ax[0].plot(energy_group,
                                   c=line_color_other,
                                   alpha=0.3)
                        ax[0].plot(
                            range(dec_to_obs(context_start, obs_per_hour), (dec_to_obs(context_end, obs_per_hour) + m)),
                            energy_group_anomaly[
                            dec_to_obs(context_start, obs_per_hour):(dec_to_obs(context_end, obs_per_hour) + m)],
                            c=line_color_context,
                            linewidth=line_size,
                            linestyle=line_style_context)
                        ax[0].plot(energy_group_anomaly,
                                   c=line_color_context,
                                   linewidth=line_size,
                                   linestyle=line_style_other)
                        ax[0].set_title(
                            "Anomaly " + str(j + 1) + " - Severity " + str(int(cmp_ad_score[anomaly_index])))
                        # removing top and right borders
                        ax[0].spines['top'].set_visible(False)
                        ax[0].spines['right'].set_visible(False)

                        ax[1].plot(power_group,
                                   c=line_color_other,
                                   alpha=0.3)
                        ax[1].plot(
                            range(dec_to_obs(context_start, obs_per_hour), (dec_to_obs(context_end, obs_per_hour) + m)),
                            power_group_anomaly[
                            dec_to_obs(context_start, obs_per_hour):(dec_to_obs(context_end, obs_per_hour) + m)],
                            c=line_color_context,
                            linewidth=line_size,
                            linestyle=line_style_context)
                        ax[1].plot(power_group_anomaly,
                                   c=line_color_context,
                                   linewidth=line_size,
                                   linestyle=line_style_other)
                        ax[1].set_ylim([min_power, max_power])
                        ax[1].set_yticks(ticks_power)
                        ax[1].set_title(date.day_name() + " " + str(date)[:10])
                        # removing top and right borders
                        ax[1].spines['top'].set_visible(False)
                        ax[1].spines['right'].set_visible(False)
                    else:
                        ax[j, 0].plot(energy_group,
                                      c=line_color_other,
                                      alpha=0.3)
                        ax[j, 0].plot(
                            range(dec_to_obs(context_start, obs_per_hour), (dec_to_obs(context_end, obs_per_hour) + m)),
                            energy_group_anomaly[
                            dec_to_obs(context_start, obs_per_hour):(dec_to_obs(context_end, obs_per_hour) + m)],
                            c=line_color_context,
                            linewidth=line_size,
                            linestyle=line_style_context)
                        ax[j, 0].plot(energy_group_anomaly,
                                      c=line_color_context,
                                      linewidth=line_size,
                                      linestyle=line_style_other)
                        ax[j, 0].set_title(
                            "Anomaly " + str(j + 1) + " - Severity " + str(int(cmp_ad_score[anomaly_index])))
                        # removing top and right borders
                        ax[j, 0].spines['top'].set_visible(False)
                        ax[j, 0].spines['right'].set_visible(False)

                        ax[j, 1].plot(power_group,
                                      c=line_color_other,
                                      linewidth=line_size,
                                      alpha=0.3)
                        ax[j, 1].plot(
                            range(dec_to_obs(context_start, obs_per_hour), (dec_to_obs(context_end, obs_per_hour) + m)),
                            power_group_anomaly[
                            dec_to_obs(context_start, obs_per_hour):(dec_to_obs(context_end, obs_per_hour) + m)],
                            c=line_color_context,
                            linewidth=line_size,
                            linestyle=line_style_context)
                        ax[j, 1].plot(power_group_anomaly,
                                      c=line_color_context,
                                      linewidth=line_size,
                                      linestyle=line_style_other)
                        ax[j, 1].set_ylim([min_power, max_power])
                        ax[j, 1].set_yticks(ticks_power)
                        ax[j, 1].set_title(date.day_name() + " " + str(date)[:10])
                        # removing top and right borders
                        ax[j, 1].spines['top'].set_visible(False)
                        ax[j, 1].spines['right'].set_visible(False)
                if num_anomalies_to_show == 1:
                    ax[0].set_xticks(range(0, 97, 24))
                    ticklabels = ["{hour}:00".format(hour=(x // obs_per_hour)) for x in range(0, 97, 24)]
                    # ticklabels[-1] = ""
                    ax[0].set_xticklabels(ticklabels)
                else:
                    ax[0, 0].set_xticks(range(0, 97, 24))
                    ticklabels = ["{hour}:00".format(hour=(x // obs_per_hour)) for x in range(0, 97, 24)]
                    # ticklabels[-1] = ""
                    ax[0, 0].set_xticklabels(ticklabels)

                plt.tight_layout()

                # ax[num_anomalies_to_show // 2, 0].set_ylabel("Power [kW]")
                # ax[num_anomalies_to_show - 1, 1].set_xlabel("Time of day")

                plt.savefig(
                    path_to_figures + context_string_small + os.sep + 'anomalous_profiles__' + group_name + '.png',
                    dpi=dpi_resolution,
                    bbox_inches='tight')
                plt.cla()
                plt.close(fig)
                '''
                # print the execution time
                time_interval_group = datetime.datetime.now() - begin_time_group
                hours, remainder = divmod(time_interval_group.total_seconds(), 3600)
                minutes, seconds = divmod(remainder, 60)
                string_anomaly_print = '- %s (%.3f s) \t-> %.d anomalies' % (
                    group_name.replace('_', ' '), seconds, num_anomalies_to_show)
                print(string_anomaly_print)

            # if no anomaly to show not visualize
            else:
                string_anomaly_print = "- " + group_name.replace('_', ' ') + ' (-) \t\t-> no anomalies'
                print(string_anomaly_print, "green")

            # save intermediate results

            # filter only where cluster
            df_result_context_cluster = df_result_context_cluster[df_result_context_cluster.cluster == True]

            # drop cluster column
            df_result_context_cluster = df_result_context_cluster.drop(['cluster'], axis=1)

            df_result_context_cluster["vector_ad_cmp"] = vector_ad_cmp
            df_result_context_cluster["vector_ad_energy"] = vector_ad_energy

            mean_energy = mean(df_result_context_cluster["vector_ad_energy"])

            df_result_context_cluster["vector_ad_energy_absolute"] = df_result_context_cluster[
                                                                         "vector_ad_energy"] - mean_energy
            df_result_context_cluster["vector_ad_energy_relative"] = (df_result_context_cluster[
                                                                          "vector_ad_energy"] / mean_energy - 1) * 100
            df_result_context_cluster["vector_ad_temperature"] = zscore(vector_ad_temperature)

            df_result_context_cluster.to_csv(
                os.path.join(path_to_data, context_string_small, f'anomaly_results_{group_name}.csv'), index=False)

        # at the end of loop on groups save dataframe corresponding to given context or append to existing one
        if df_anomaly_results.empty:
            df_anomaly_results = df_anomaly_context
        else:
            # concatenate dataframes by column
            df_anomaly_results = pd.concat([df_anomaly_results, df_anomaly_context], axis=1)
            # remove redundant columns
            df_anomaly_results = df_anomaly_results.loc[:, ~df_anomaly_results.columns.duplicated()]

    # at the end of loop on context save dataframe of results
    df_anomaly_results.to_csv(os.path.join(path_to_data, "anomaly_results.csv"))
    df_contexts.to_csv(os.path.join(path_to_data, "contexts.csv"), index=False)

    # print the execution time
    total_time = datetime.datetime.now() - begin_time
    hours, remainder = divmod(total_time.total_seconds(), 3600)
    minutes, seconds = divmod(remainder, 60)
    print('\n*********************\n' + "END: " + datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    print("TOTAL " + str(int(minutes)) + ' min ' + str(int(seconds)) + ' s')

    save_report(context)
