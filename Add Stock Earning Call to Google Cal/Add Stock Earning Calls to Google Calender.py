# -*- coding: utf-8 -*-
"""
Created on Sun Oct 12 17:25:43 2025

@author: adiag
"""
# pip install finnhub-python google-api-python-client google-auth google-auth-oauthlib google-auth-httplib2

import finnhub
import datetime
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
import pickle
import os

os.chdir(r'D:\OneDrive - Northeastern University\Jupyter Notebook\Python scripts\Add Stock Earning Call to Google Cal')

# === CONFIG ===
SCOPES = ['https://www.googleapis.com/auth/calendar']
CALENDAR_ID = 'primary'
TICKERS = ['AAPL', 'MSFT', 'GOOGL', 'NVDA', 'TSLA', 'CRWV', 'AMZN']
FINNHUB_API_KEY = 'd3m2pfpr01qkjsse3qk0d3m2pfpr01qkjsse3qkg'  # Replace with your actual key


# === GOOGLE CALENDAR AUTH ===
def get_calendar_service():
    creds = None
    if os.path.exists('token.pkl'):
        with open('token.pkl', 'rb') as token:
            creds = pickle.load(token)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file('credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        with open('token.pkl', 'wb') as token:
            pickle.dump(creds, token)
    service = build('calendar', 'v3', credentials=creds)
    return service

# === FETCH UPCOMING EARNINGS ===
def get_upcoming_earnings(tickers):
    import datetime
    finnhub_client = finnhub.Client(api_key=FINNHUB_API_KEY)
    today = datetime.date.today()
    six_months = today + datetime.timedelta(days=180)
    earnings = {}

    for ticker in tickers:
        try:
            data = finnhub_client.earnings_calendar(
                symbol=ticker,
                _from=today.isoformat(),
                to=six_months.isoformat()
            )
            results = data.get('earningsCalendar', [])
            if results:
                # sort just in case multiple dates come back
                results.sort(key=lambda x: x.get('date'))
                entry = results[0]
                date_str = entry.get('date')
                if date_str:
                    date = datetime.datetime.strptime(date_str, '%Y-%m-%d')
                    earnings[ticker] = date
                    print(f"{ticker} → Upcoming earnings on {date.date()}")
            else:
                print(f"{ticker} → No announced earnings within next 6 months.")
        except Exception as e:
            print(f"Error fetching earnings for {ticker}: {e}")

    return earnings


# === ADD TO GOOGLE CALENDAR ===
def add_earnings_event(service, ticker, date):
    event = {
        'summary': f'{ticker} Earnings Call',
        'description': f'Upcoming earnings call for {ticker}',
        'start': {
            'dateTime': date.strftime('%Y-%m-%dT09:00:00'),
            'timeZone': 'America/New_York',
        },
        'end': {
            'dateTime': date.strftime('%Y-%m-%dT10:00:00'),
            'timeZone': 'America/New_York',
        },
        'reminders': {
            'useDefault': False,
            'overrides': [
                {'method': 'popup', 'minutes': 60 * 24},
                {'method': 'popup', 'minutes': 60},
            ],
        },
    }
    service.events().insert(calendarId=CALENDAR_ID, body=event).execute()
    print(f"✅ Added {ticker} earnings event on {date.date()}")

# === MAIN ===
def main():
    print("Fetching upcoming earnings (Finnhub)...")
    earnings = get_upcoming_earnings(TICKERS)
    if not earnings:
        print("No upcoming earnings found.")
        return

    # service = get_calendar_service()
    # for ticker, date in earnings.items():
    #     add_earnings_event(service, ticker, date)

if __name__ == '__main__':
    main()
    
    