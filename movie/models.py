from django.db import models
from django.contrib.auth.models import User

class UserMovie(models.Model):
    STATUS_CHOICES = [
        ('will_watch', 'Will Watch'),
        ('watched', 'Watched'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE)
    movie_id = models.IntegerField()
    favorite = models.BooleanField(default=False)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, null=True, blank=True)

    class Meta:
        unique_together = ('user', 'movie_id')

    def __str__(self):
        return f"{self.user.username} - {self.movie_id}"