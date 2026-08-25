from youtube_transcript_api import YouTubeTranscriptApi
from transformers import pipeline
import re

# Function to extract video ID from URL
def extract_video_id(url):
    # Handles different formats of YouTube URLs
    video_id_match = re.search(r"(?:v=|youtu\.be/|embed/)([^&?/]+)", url)
    if video_id_match:
        return video_id_match.group(1)
    else:
        raise ValueError("Invalid YouTube URL")

# Function to fetch transcript
def get_transcript(video_url):
    video_id = extract_video_id(video_url)
    transcript = YouTubeTranscriptApi.get_transcript(video_id)
    full_text = " ".join([entry['text'] for entry in transcript])
    return full_text

# Function to summarize transcript
def summarize_text(text, max_chunk_length=1000):
    summarizer = pipeline("summarization", model="t5-base", tokenizer="t5-base")

    # Split text into chunks to avoid token limit
    chunks = [text[i:i+max_chunk_length] for i in range(0, len(text), max_chunk_length)]
    summaries = []

    for chunk in chunks:
        summary = summarizer(chunk, max_length=150, min_length=40, do_sample=False)[0]['summary_text']
        summaries.append(summary)

    return "\n".join(summaries)

# === Main Execution ===
if __name__ == "__main__":
    youtube_url = input("Enter the YouTube video URL: ")

    try:
        transcript = get_transcript(youtube_url)
        notes = summarize_text(transcript)
        print("\n--- Notes / Summary ---\n")
        print(notes)

    except Exception as e:
        print(f"Error: {e}")
