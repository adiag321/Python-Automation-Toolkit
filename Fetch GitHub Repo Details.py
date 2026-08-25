import requests
import pandas as pd

def get_github_repositories(username, per_page=100):
    repos = []
    page = 1
    while True:
        url = f"https://api.github.com/users/{username}/repos"
        params = {"per_page": per_page, "page": page}
        response = requests.get(url, params=params)
        if response.status_code != 200:
            print(f"Error: {response.status_code} - {response.json().get('message')}")
            break
        data = response.json()
        if not data:
            break
        repos.extend(data)
        page += 1

    # Extract key info into a list of dicts
    repo_info = [{
        "name": repo["name"],
        "full_name": repo["full_name"],
        "description": repo["description"],
        "html_url": repo["html_url"],
        "language": repo["language"],
        "stargazers_count": repo["stargazers_count"],
        "forks_count": repo["forks_count"],
        "created_at": repo["created_at"],
        "updated_at": repo["updated_at"],
        "private": repo["private"]
    } for repo in repos]

    return pd.DataFrame(repo_info)

if __name__ == "__main__":
    username = input("Enter the GitHub username: ")
    df = get_github_repositories(username)
    print(f"\nFound {len(df)} repositories for user '{username}'\n")
    print(df.head())  # Display first few rows

    # Optional: save to CSV
    df.to_csv(f"{username}_github_repos.csv", index=False)
