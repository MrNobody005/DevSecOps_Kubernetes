from django.urls import path
from django.contrib.auth import views as auth_views
from .views import register_view
from movie.views import movie_list, toggle_favorite, set_status, home

urlpatterns = [
    path('register/', register_view, name='register'),
    path('login/', auth_views.LoginView.as_view(template_name='accounts/login.html'), name='login'),
    path('logout/', auth_views.LogoutView.as_view(next_page='/'), name='logout'),
    path('profile/', home, name='profile'),
    path('', movie_list, name='home'),
    path('<int:movie_id>/favorite/', toggle_favorite, name='toggle_favorite'),
    path('<int:movie_id>/status/<str:status>/', set_status, name='set_status'),
]
