# -*- coding: utf-8 -*-
"""
Created on Wed Oct 15 11:45:26 2025

@author: adiag
"""
import yfinance as yf
import pandas as pd
from datetime import datetime, timedelta

STOCK_LIST = ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'NVDA', 'TSLA', 'META', 'AMD']

def get_ratings(ticker, days=30):
    try:
        stock = yf.Ticker(ticker)
        rec = stock.upgrades_downgrades if hasattr(stock, 'upgrades_downgrades') else stock.recommendations
        
        if rec is None or rec.empty:
            return None
        
        cutoff = pd.Timestamp(datetime.now() - timedelta(days=days))
        if not isinstance(rec.index, pd.DatetimeIndex):
            rec.index = pd.to_datetime(rec.index)
        if rec.index.tz:
            cutoff = cutoff.tz_localize(rec.index.tz)
        
        rec = rec[rec.index >= cutoff]
        if not rec.empty:
            rec['Ticker'] = ticker
            return rec
    except Exception as e:
        print(f"Error {ticker}: {e}")
    return None

all_ratings = []
for ticker in STOCK_LIST:
    ratings = get_ratings(ticker)
    if ratings is not None:
        all_ratings.append(ratings)

if all_ratings:
    df = pd.concat(all_ratings).sort_values(by = ['Ticker'], ascending=False)
    df.to_csv(f"ratings_{datetime.now().strftime('%Y%m%d')}.csv")
    print(f"\nSaved to ratings_{datetime.now().strftime('%Y%m%d')}.csv")
else:
    print("No ratings found")