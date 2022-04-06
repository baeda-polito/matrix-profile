# Author:       Roberto Chiosa
# Copyright:    Roberto Chiosa, © 2022
# Email:        roberto.chiosa@polito.it
#
# Created:      05/04/22
# Script Name:  read_index.py
# Path:         Polito_Usecase/data
#
# Script Description:
#
#
# Notes:
import numpy as np
import pandas as pd

if __name__ == '__main__':
    df_index = pd.read_csv("./ctx_from05_15_to06_15_m02_30/match_index_query_Cluster_1.csv", header=None)
    df_cmp = pd.read_csv("./ctx_from05_15_to06_15_m02_30/plot_cmp_Cluster_1.csv", header=None)
    df_cluster = pd.read_csv("./group_cluster.csv")
    df_tot = pd.read_csv("./polito.csv")

    ####
    # calculat mean shift in contexts

    # context_vector = [
    #     "ctx_from00_00_to01_00_m05_15",
    #     "ctx_from05_15_to06_15_m02_30",
    #     "ctx_from07_45_to08_45_m06_45",
    #     "ctx_from14_30_to15_30_m03_30",
    #     "ctx_from18_00_to19_00_m05_00"
    # ]
    #
    # for cmp_df in context_vector:
    #     df_index_context = pd.read_csv("./{}/match_index_query.csv".format(cmp_df), header=None)
    #     # substitute -1 with NAN
    #     df_index_context[df_index_context == -1] = None
    #     # get minimum value per row
    #     df_minimum = df_index_context.apply(lambda x: np.nanmin(x), axis=1, raw=True)
    #     # get columns
    #     cols = df_index_context.columns
    #     # get intex shifted
    #     df_index_shifted = df_index_context.apply(lambda x: x - df_minimum, axis=0, raw=True)
    #     print(cmp_df)
    #     count = df_index_shifted.stack().value_counts()
    #     print(count / (365 * 365) * 100)

    # trova a mano l'indice
    # 44

    df_index.loc[42].value_counts()

    df_tot.loc[34584]

