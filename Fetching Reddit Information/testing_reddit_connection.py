# -*- coding: utf-8 -*-
"""
Created on Mon Jun 30 10:29:21 2025

@author: adiag
"""
import nest_asyncio
import asyncio
import asyncpraw
import os
import re
from dotenv import load_dotenv
from datetime import datetime, timezone, timedelta

nest_asyncio.apply()
load_dotenv()

REDDIT_CLIENT_ID = os.getenv("REDDIT_CLIENT_ID")
REDDIT_CLIENT_SECRET = os.getenv("REDDIT_CLIENT_SECRET")
REDDIT_USER_AGENT = os.getenv("REDDIT_USER_AGENT")

TICKER_REGEX = re.compile(r'\b[A-Z]{1,5}\b')
SUBREDDITS = ["stocks", "investing", "WallStreetBets", "StockMarket", "SecurityAnalysis"]

def extract_tickers(title):
    tickers = TICKER_REGEX.findall(title)
    return tickers

async def fetch_recent_stock_news():
    reddit = asyncpraw.Reddit(
        client_id=REDDIT_CLIENT_ID,
        client_secret=REDDIT_CLIENT_SECRET,
        user_agent=REDDIT_USER_AGENT
    )

    now = datetime.now(timezone.utc)
    one_day_ago = now - timedelta(days=1)

    for sub in SUBREDDITS:
        subreddit = await reddit.subreddit(sub)
        print(f"\n📈 Posts from last 24 hours in r/{sub}:\n")

        count = 0
        async for post in subreddit.new(limit=100):  # fetch up to 100 newest posts
            post_time = datetime.fromtimestamp(post.created_utc, tz=timezone.utc)
            if post_time < one_day_ago:
                # Posts are sorted newest first, so once we hit older than 24h, we can stop fetching more
                break

            tickers = extract_tickers(post.title)
            tickers_str = ", ".join(tickers) if tickers else "None"
            created_time = post_time.strftime('%Y-%m-%d %H:%M:%S UTC')

            print(f"🕒 Time: {created_time}")
            print(f"🏷️ Flair: {post.link_flair_text}")
            print(f"💹 Tickers Found: {tickers_str}")
            print(f"📰 Title: {post.title}")
            print(f"🔗 URL: {post.url}")
            print(f"💬 Score: {post.score}")
            print("-" * 60)

            count += 1

        if count == 0:
            print("No posts found from the last 24 hours.")
            
    await reddit.close()

# ✅ Correct way to run async in a script
if __name__ == "__main__":
    asyncio.run(fetch_recent_stock_news())
