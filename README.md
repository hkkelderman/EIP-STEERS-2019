# EIP-Steers-2019

This repository is the data, code, and analyses used to deploy a Dash App.

The link to the deployed app is here: [EIP 2019 STEERS](https://eipsteers2019.herokuapp.com/)

The analysis was performed in R, while the app was built in Python, using Dash.

## The Data

The Texas Commission on Environmental Quality (TCEQ) maintains a database on air upset emissions across the state that is reported to them by industry. Upset events are non-permitted emissions by facilities that are caused by maintenance, start-up/shut-down, or leaks, and they happen quite frequently. You can find individual reports on the [Texas Emission Event Report Database](https://www2.tceq.texas.gov/oce/eer/), or you can search for a multiple reports within a date range. These emission event reports give information on the facility, the location, when the event occurred and for how long, the pollutants emitted, and how much of each pollutant was emitted.

This database is scrapable, and when my organization want to look at trends for the current year, that's what I do, but at the begginning of every year, we submit an Open Records Request asking TCEQ to send us all of the data for the previous year. What they end up sending us includes more information than can be found in the reports online, which is why we do it. Upon receiving the data, I spend quite a bit of time just cleaning it up and sorting the contaminants into different categories, like Hazardous Air Pollutants (HAPs) or Volatile Organic Compounds (VOCs). 

Once the data is clean, I can perform my analysis. On the surface, we're interested in the the total emissions of each contaminant category in various regions across Texas. We look at emissions for all of Texas, the Permian Basin, and the areas surrounding Houston and Port Arthur. We also try to identify big emitters in all these regions as well, as potential opportunities for enforcement.


## The App

This Dash App was a way to summarize and visualize the data we look at every year. My intention was to host the app on our website, so that communities could use it as a way to see what the pollution looks like in their area, but we are no longer going to publish the app. This is why it's a little rough around the edges: the app loads pretty slowly, the front end could be tightened up, new features were going to be added, and some of the analyses needed to be adjusted. Instead, we want to focus on more than just summary data, maybe looking at specific industry types or regions in TX that tell a more interesting story. If that's the case, I hope to create a different (better) app to showcase that data.

For now, I'm going to leave this as it is. It was my first attempt at a Dash app and I'm pretty proud of it. If work slows down or I have more time in the future, maybe I'll come back to this and clean it up.
