"""
Author:       Roberto Chiosa
Copyright:    Roberto Chiosa, © 2024
Email:        roberto.chiosa@pinvision.it

Created:      31/05/24
Script Name:  report.py
Path:         src/cmp

Script Description:


Notes:
"""
import os

from jinja2 import Environment, FileSystemLoader

if __name__ == '__main__':
    # Define the data to be used in the template
    context = {
        'title': 'Energy Bill Analysis Report',
        'subtitle': 'Detailed analysis of your energy consumption',
        'summary': 'This report provides a comprehensive analysis of your energy consumption over the past year...',
        'sections': [
            {"title": "Energy Saving Tips", "content": "Here are some tips to save energy..."},
            {"title": "Future Projections", "content": "Based on your current usage, here are the projections..."}
        ],
        'footer_text': '© 2024 Energy Bill Analysis Report'
    }

    # Set up the Jinja2 environment
    env = Environment(loader=FileSystemLoader('.'))
    template = env.get_template(os.path.join('templates', 'base.html'))

    # Render the template with the data
    html_content = template.render(context)

    # Save the rendered HTML to a file (optional, for inspection)
    with open(os.path.join('results', 'reports', 'report.html'), 'w') as file:
        file.write(html_content)
