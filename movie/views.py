import requests
from django.conf import settings
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import UserMovie

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

@login_required
def toggle_favorite(request, movie_id):
    user_movie, created = UserMovie.objects.get_or_create(
        user=request.user,
        movie_id=movie_id
    )
    user_movie.favorite = not user_movie.favorite
    user_movie.save()
    return redirect('home')

@login_required
def set_status(request, movie_id, status):
    user_movie, created = UserMovie.objects.get_or_create(
        user=request.user,
        movie_id=movie_id
    )
    
    if status == "will_watch":
        user_movie.status = "will_watch"
    elif status == "watched":
        user_movie.status = "watched"
    user_movie.save()
    return redirect('home')

@login_required
def home(request):
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

    user_movies = UserMovie.objects.filter(user=request.user)
    user_movie_map = {um.movie_id: um for um in user_movies}

    for m in movies:
        m['user_data'] = user_movie_map.get(m['id'])

    return render(request, 'accounts/home.html', { 'movies': movies })