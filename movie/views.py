import requests
from django.conf import settings
from django.shortcuts import render

def movie_list(request):
    url = "https://api.themoviedb.org/3/movie/now_playing"
    params = {
        "api_key": settings.TMDB_API_KEY,
        "language": "en-US",
        "page": 1
    }

    response = requests.get(url, params=params)
    if response.status_code == 200:
        data = response.json()
        movies = data.get("results", [])
    else:
        movies = []  # fallback if API fails

    return render(request, "movie_list.html", {"movies": movies})