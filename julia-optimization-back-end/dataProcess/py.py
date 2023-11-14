# 需先安装epw包
from epw import weather
#import pandas as pd

a=weather.Weather()
fn = 'CHN_SN_Yulin.536460_TMYx.2007-2021.epw'
a.read(fn)
df = a.dataframe
df.to_csv('data.csv')
