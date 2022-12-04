# usda_fiad_datamine_2022

USDA FIA and Purdue Data Mine 2022 class. 


The goal of this team: DATA-PROCESSING TEAM

Is to: 

+ Produce a simplified dataset from USDA-FIA's datasets.
+ Have the simplified dataset measure tree density. 
+ Have 100% coverage of the chosen state using BINs of a certian resoultion. 

The current plan to achieve this is this: 

+ Go plot by plot for a given state.
+ Note the year the plot was measured.
+ If subplots exist:
+ + For each subplot count it's trees and divide by the size of a subplot.
+ + Average the subplots together.
+ (old data) Else if no subplots:
+ + Count trees divide by plot size
+ Delete all the trees and plots/subplots and only keep one density per location (plot) per year it was measured.
+ Draw a grid over the entire state and in each square (bin) average all the densities within it then we can say that entire area has that average density and now we have 100% coverage of the State of each year.
+ + This data is now a fully populated time series of density for a give state.