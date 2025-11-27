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
    title = request.GET.get('title', '')
    poster_path = request.GET.get('poster_path', '')
    release_date = request.GET.get('release_date', None)

    user_movie, created = UserMovie.objects.get_or_create(
        user=request.user,
        movie_id=movie_id,
        defaults={
            'title': title,
            'poster_path': poster_path,
            'release_date': release_date
        }
    )

    user_movie.favorite = not user_movie.favorite
    user_movie.save()
    return redirect('profile')

@login_required
def set_status(request, movie_id, status):
    title = request.GET.get('title', '')
    poster_path = request.GET.get('poster_path', '')
    release_date = request.GET.get('release_date', None)

    user_movie, created = UserMovie.objects.get_or_create(
        user=request.user,
        movie_id=movie_id,
        defaults={
            'title': title,
            'poster_path': poster_path,
            'release_date': release_date
        }
    )

    if status in ['will_watch', 'watched']:
        user_movie.status = status
        user_movie.save()

    return redirect('profile')

@login_required
def home(request):
    user_movies = UserMovie.objects.filter(user=request.user)
    
    favorite_movies = [m for m in user_movies if m.favorite]
    will_watch_movies = [m for m in user_movies if m.status == 'will_watch']
    watched_movies = [m for m in user_movies if m.status == 'watched']

    return render(request, 'accounts/home.html', {
        'favorite_movies': favorite_movies,
        'will_watch_movies': will_watch_movies,
        'watched_movies': watched_movies
    })
