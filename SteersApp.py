import pandas as pd
import plotly.express as px
from urllib.request import urlopen
import json

with urlopen('https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json') as response:
    counties = json.load(response)

import dash
import dash_core_components as dcc
import dash_html_components as html
from dash.dependencies import Input, Output

external_stylesheets = ['https://codepen.io/hkkelderman/pen/oNbpZKo.css']
colors = {
    'background': '#212a45',
    'text': '#F7F9FB',
    'text2': '#A6ECE0'
}

app = dash.Dash(__name__,
                external_stylesheets=external_stylesheets)
server = app.server

token = 'pk.eyJ1Ijoia2tlbGRlcm1hbiIsImEiOiJja2NmMXNpamQwYnduMndwNm85aWswbm55In0.sQPkloP8sjAygp_zUOnkug'

chemicals = pd.read_excel("001_Chemicals.xlsx")
contaminants = pd.read_excel("002_Contaminants.xlsx")
emissions = pd.read_excel("003_Emissions.xlsx", dtype={'fips': str})
facilities = pd.read_excel("004_Top Facilities.xlsx")

# App Layout --------------------------------------------------------------------------------------------------------
app.layout = html.Div([
    html.H1("2019 Texas Emissions Event Database (STEERS)",
            style={
                'text-align': 'center',
                'color': colors['text']
            }),

    dcc.Dropdown(id="slct_region",
                 options=[
                     {"label": "Texas", "value": "Texas"},
                     {"label": "Permian Basin", "value": "Permian Basin"},
                     {"label": "Gulf Coast", "value": "Gulf Coast"}],
                 multi=False,
                 value="Texas",
                 style={'width': "40%"}),

    html.Br(),
    html.Div([
        html.Div([
            html.H6('Contaminant Type', style={'color': colors['text']}),
            html.P('Select the contaminant you wish to filter the map by:',
                   style={'color': colors['text']}),
            html.Br(),
            dcc.RadioItems(id="slct_contam",
                           options=[
                               {"label": "All", "value": "All"},
                               {"label": "Greenhouse Gases", "value": "GHG"},
                               {"label": "HAPs", "value": "HAP"},
                               {"label": "Nitrogen Oxides", "value": "NOX"},
                               {"label": "Particulate Matter", "value": "PM"},
                               {"label": "Sulfur Dioxide", "value": "SO2"},
                               {"label": "Sulfur Oxides", "value": "SOX"},
                               {"label": "Toxics", "value": "TOX"},
                               {"label": "VOCs", "value": "VOC"},
                               {"label": "Other", "value": "Other"}],
                           value="All", style={'color': colors['text']}),
            html.Br(),
            html.H6('Total tons:',
                    style={'color': colors['text']}),
            html.H6(id='filter_sum',
                   style={'color': colors['text']})
        ], className='plotContainer three columns'),
        html.Div([
            html.H5("Emissions by County",
                    style={'text-align': 'center',
                           'color': colors['text']}),
            dcc.Graph(id='emission_map')], className='plotContainer nine columns'),
    ]),

    html.Div([
        html.Div([
            html.H5("Emissions by Contaminant Type",
                    style={'text-align': 'center',
                           'color': colors['text']}),
            dcc.Graph(id='my_contams')],
            className='plotContainer five columns',
        ),
        html.Div([
            html.H5('Top 10 Contaminants Emitted',
                    style={'text-align': 'center',
                           'color': colors['text']}),
            dcc.Graph(id='chemical_graph')],
            className='plotContainer seven columns',
        ),
    ]),

    html.Div([
        html.Div([
            html.H5("Facility and Event Map",
                    style={'text-align': 'center',
                           'color': colors['text']}),
            dcc.Graph(id='facility_map')],
            className='plotContainer nine columns'),
        html.Div([
            html.H5("Facility Info (3-mile)",
                    style={'text-align': 'center',
                           'color': colors['text']}),
            html.P('Click on a facility to learn more about it.',
                   style={'color': colors['text']}),
            html.P([html.P('Facility: '), html.P(id='facility_click', style={'color': colors['text2']})]),
            html.P([html.P('Total Population: '), html.P(id='population_click', style={'color': colors['text2']})]),
            html.P([html.P('Percent Below Poverty Level: '), html.P(id='pov_click', style={'color': colors['text2']})]),
            html.P([html.P('Percent Minority: '), html.P(id='min_click', style={'color': colors['text2']})]),
            html.P([html.P('Top 5 Contaminants: '), html.P(id='contam_click', style={'color': colors['text2']})]),
            html.P([html.P('Link: '), dcc.Link('ECHO Link', id='link_click', href='/')]),
        ],
            className='textContainer three columns')
    ])
])


# Callback -----------------------------------------------------------------------------------------------------------
@app.callback(
    [Output('emission_map', 'figure'),
     Output('filter_sum', 'children')],
    [Input('slct_region', 'value'),
     Input('slct_contam', 'value')])
def update_fig2(region, contam):
    dff3 = emissions.copy()
    dff3a = dff3[(dff3['Region'] == region)]
    dff3b = dff3a[dff3a['Type'] == contam]
    sum = round(dff3b['Tons Emitted'].sum(), 0)

    fig2 = px.choropleth(data_frame=dff3b,
                         geojson=counties,
                         color_continuous_scale='Oranges',
                         locations="FIPS",
                         color='Tons Emitted',
                         hover_name='County',
                         hover_data=['Tons Emitted', 'Number of Events'],
                         scope='usa'
                         )
    fig2.update_geos(fitbounds="locations")
    fig2.update_layout(font={'family': 'Open Sans', 'color': colors['text']})
    fig2.layout.paper_bgcolor = colors['background']
    fig2.update_layout(margin={"r": 0, "t": 10, "l": 0, "b": 10})
    return fig2, sum


@app.callback(
    Output('my_contams', 'figure'),
    [Input('slct_region', 'value')])
def update_fig1(region):
    dff1 = contaminants.copy()
    dff1 = dff1[dff1['Region'] == region]
    sum_contam = dff1['Tons Emitted'].sum()
    pie_colors = ['#31708E', '#BCAF9C', '#14281D', '#6D3D14', '#551B14', '#553D36']

    fig1 = px.pie(
        data_frame=dff1,
        values='Tons Emitted',
        names='Contaminant Type',
        hover_data=['Tons Emitted'],
        hole=.3,
        title='Total Tons of Emissions: {}'.format(sum_contam)
    )
    fig1.update_traces(textposition='inside', textinfo='percent+label',
                       marker=dict(colors=pie_colors, line=dict(color=colors['text'], width=2))
                       )
    fig1.update_layout(font={'color': colors['text']})
    fig1.layout.paper_bgcolor = colors['background']
    return fig1


@app.callback(
    Output('chemical_graph', 'figure'),
    [Input('slct_region', 'value')])
def update_fig4(region):
    dff2 = chemicals.copy()
    dff2 = dff2[dff2['Region'] == region]
    dff2 = dff2[['Contaminant', 'Number of Events', 'Tons Emitted']]

    fig4 = px.bar(
        data_frame=dff2,
        x='Contaminant',
        y='Tons Emitted',
        hover_data=['Tons Emitted']
    )
    fig4.update_traces(marker_color='#CC4E00')
    fig4.update_layout(font={'color': colors['text']})
    fig4.layout.paper_bgcolor = colors['background']
    fig4.layout.plot_bgcolor = colors['background']
    return fig4


@app.callback(
    Output('facility_map', 'figure'),
    [Input('slct_region', 'value')])
def update_fig3(region):
    dff4 = facilities.copy()
    dff4a = dff4[(dff4['Region'] == region)]
    dff4b = dff4a[(dff4a['Range'] == '3-mile')]

    fig3 = px.scatter_mapbox(dff4b,
                             lat='Latitude',
                             lon='Longitude',
                             hover_name='Facility',
                             hover_data=['Number of Events', 'Tons Emitted'],
                             color='Tons Emitted',
                             color_continuous_scale='Viridis',
                             custom_data=['Contaminants', 'Range', 'Population', 'Below Poverty',
                                          'Minority Population', 'Link'],
                             zoom=5)
    fig3.update_geos(fitbounds="locations")
    fig3.update_traces(marker=dict(size=12))
    fig3.update_layout(mapbox_style="dark", mapbox_accesstoken=token)
    fig3.layout.paper_bgcolor = colors['background']
    fig3.update_layout(font={'family': 'Open Sans', 'color': colors['text']})
    fig3.update_layout(margin={"r": 0, "t": 10, "l": 10, "b": 0})
    return fig3


@app.callback(
    [Output('facility_click', 'children'),
     Output('population_click', 'children'),
     Output('pov_click', 'children'),
     Output('min_click', 'children'),
     Output('contam_click', 'children'),
     Output('link_click', 'children')],
    [Input('facility_map', 'clickData')])
def update_info(selection):
    if selection:
        facility = [selection['points'][0]['hovertext']]
        population = [selection['points'][0]['customdata'][2]]
        poverty = [selection['points'][0]['customdata'][3]]
        minority = [selection['points'][0]['customdata'][4]]
        contams = [selection['points'][0]['customdata'][0]]
        link = [selection['points'][0]['customdata'][5]]
        return facility, population, poverty, minority, contams, link
    else:
        return [["No Facility Selected"], ["No Facility Selected"], ["No Facility Selected"],
                ["No Facility Selected"], ["No Facility Selected"], ["No Facility Selected"]]

# Execute app --------------------------------------------------------------------------------------------------------
if __name__ == '__main__':
    app.run_server(debug=True, )
