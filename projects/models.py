from django.db import models
from django.db.models import permalink
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.conf import settings
from imagekit.models import ImageSpecField
from imagekit.processors import ResizeToFill
from imagekit.lib import Image

import os

# define dynamic upload path for the file field
def get_file_upload_path(instance, filename):
	return os.path.join("files/file_%s" % instance.slug, filename)

# define dynamic upload path for the avatar field
def get_avatar_upload_path(instance, filename):
	return os.path.join("avatars/img_%s" % instance.user.username, filename)

class Project(models.Model):
	name = models.CharField(max_length=100)
	slug = models.SlugField(max_length=100, unique=True)
	description = models.TextField()
	date = models.DateTimeField(auto_now_add=True)
	archived = models.BooleanField(default=False)
	company = models.ForeignKey('projects.Company', blank=True, null=True, related_name='projects')

	def __unicode__(self):
		return '%s' % self.name

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.project', [ self.slug ])

	def get_latest_discussions(self):
		return self.discussions.filter(completed=False).order_by('-date')[:2]

	def get_next_milestones(self):
		return self.milestones.filter(completed=False).order_by('-due_date')[:2]

	def get_latest_tasks(self):
		return self.get_tasks()[:2]

	def get_tasks(self):
		tasks = []
		for theList in self.lists.filter(completed=False).order_by('-date'):
			for task in theList.tasks.filter(completed=False).order_by('-due_date'):
				tasks.append(task)
		return tasks

	def get_tasks_count(self):
		return len( self.get_tasks() )

class Milestone(models.Model):
	project = models.ForeignKey('projects.Project', related_name='milestones')
	name = models.CharField(max_length=60)
	slug = models.SlugField(max_length=60, unique=True)
	date = models.DateTimeField(auto_now_add=True)
	due_date = models.DateTimeField(editable=True)
	description = models.TextField(default="", blank=True)
	completed = models.BooleanField(default=False)
	completed_date = models.DateTimeField(editable=True, blank=True, null=True)

	def __unicode__(self):
		return '%s' % self.name

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.milestone', [ self.project.slug, self.slug ])

class Discussion(models.Model):
	project = models.ForeignKey('projects.Project', related_name='discussions')
	title = models.CharField(max_length=100)
	slug = models.SlugField(max_length=100, unique=True)
	date = models.DateTimeField(auto_now_add=True)
	content = models.TextField()
	author = models.ForeignKey(User)
	private = models.BooleanField(default=False)
	completed = models.BooleanField(default=False)
	completed_date = models.DateTimeField(editable=True, blank=True, null=True)

	def __unicode__(self):
		return '%s' % self.title

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.discussion', [ self.project.slug, self.slug ])

class DiscussionComment(models.Model):
	discussion = models.ForeignKey('projects.Discussion', related_name='comments')
	date = models.DateTimeField(auto_now_add=True)
	content = models.TextField()
	author = models.ForeignKey(User)

	def __unicode__(self):
		return '%s' % self.content

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.discussion', [ self.discussion.project.slug, self.discussion.slug ])

class List(models.Model):
	project = models.ForeignKey('projects.Project', related_name='lists')
	name = models.CharField(max_length=100)
	slug = models.SlugField(max_length=100, unique=True)
	milestone = models.ForeignKey('projects.Milestone', blank=True, null=True, related_name='lists')
	date = models.DateTimeField(auto_now_add=True)
	description = models.TextField(default="", blank=True)
	author = models.ForeignKey(User, related_name='lists')
	private = models.BooleanField(default=False)
	completed = models.BooleanField(default=False)
	completed_date = models.DateTimeField(editable=True, blank=True, null=True)

	def __unicode__(self):
		return '%s' % self.name

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.list', [ self.project.slug, self.slug ])

class Task(models.Model):
	title = models.CharField(max_length=100)
	slug = models.SlugField(max_length=100, unique=True)
	list = models.ForeignKey('projects.List', related_name='tasks')
	description = models.TextField(default="", blank=True)
	date = models.DateTimeField(auto_now_add=True)
	due_date = models.DateTimeField(editable=True, blank=True, null=True)
	priority = models.IntegerField(default=99999)
	author = models.ForeignKey(User, related_name='tasks')
	responsible = models.ForeignKey(User, blank=True, null=True, related_name='tasks_responsible')
	completed = models.BooleanField(default=False)
	completed_date = models.DateTimeField(editable=True, blank=True, null=True)

	def __unicode__(self):
		return '%s' % self.title

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.task', [ self.list.project.slug, self.list.slug, self.slug ])

class TaskComment(models.Model):
	task = models.ForeignKey('projects.Task', related_name='comments')
	date = models.DateTimeField(auto_now_add=True)
	content = models.TextField()
	author = models.ForeignKey(User, related_name='task_comments')

	def __unicode__(self):
		return '%s' % self.content

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.task', [ self.task.list.project.slug, self.task.list.slug, self.task.slug ])

class File(models.Model):
	project = models.ForeignKey('projects.Project', related_name='files')
	name = models.CharField(max_length=100)
	slug = models.SlugField(max_length=100, unique=True)
	file = models.FileField(upload_to=get_file_upload_path)
	date = models.DateTimeField(auto_now_add=True)
	author = models.ForeignKey(User, related_name='files')
	original_object = models.CharField(max_length=2,default="", blank=True, choices=(
		('d', 'Discussion'),
		('dc', 'Discussion Comment'),
		('t', 'Task'),
		('tc', 'Task Comment'),
		('fc', 'File Comment'),
	))
	original_object_id = models.BigIntegerField(default=0, blank=True)
	description = models.TextField(default="", blank=True)
	private = models.BooleanField(default=False)

	def __unicode__(self):
		return '%s' % self.name

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.file', [ self.project.slug, self.slug ])

class FileComment(models.Model):
	file = models.ForeignKey('projects.File', related_name='comments')
	date = models.DateTimeField(auto_now_add=True)
	content = models.TextField()
	author = models.ForeignKey(User, related_name='file_comments')

	def __unicode__(self):
		return '%s' % self.content

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.file', [ self.file.project.slug, self.file.slug ])

class Company(models.Model):
	name = models.CharField(max_length=100)
	slug = models.SlugField(max_length=100, unique=True)
	url = models.URLField(default="", blank=True)
	users = models.ManyToManyField(User, blank=True, related_name='companies')

	def __unicode__(self):
		return '%s' % self.name

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.company', [ self.slug ])

class PrettifyAvatar(object):
	def process(self, image):
		mask = Image.open(os.path.join(settings.STATIC_ROOT, 'img/avatar-mask.png'))
		
		layer = Image.new('RGBA', image.size)
		layer.paste(mask)

		newImage = Image.composite(layer, image, layer)
		return newImage

class UserProfile(models.Model):
	user = models.OneToOneField(User)
	original_avatar = models.ImageField(upload_to=get_avatar_upload_path, help_text="200x200", blank=True)
	avatar = ImageSpecField([ResizeToFill(200, 200), PrettifyAvatar()], image_field='original_avatar', format='PNG', options={'optimize':True})
	url = models.URLField(default="", blank=True)
	phone = models.CharField(max_length=40, blank=True)
	timezone = models.CharField(max_length=50, default="Europe/Lisbon")

	def getAvatar(self):
		if not self.avatar:
			return '/static/img/default-avatar.png'
		else:
			return self.avatar.url

	@models.permalink
	def get_absolute_url(self):
		return ('projects.views.user', [ self.user.username ])

def get_user_profile(instance):
	try:
		parsedProfile = UserProfile.objects.get(user=instance)
	except:
		UserProfile.objects.create(user=instance)

		parsedProfile = UserProfile.objects.get(user=instance)

	return parsedProfile

def create_user_profile(sender, instance, created, **kwargs):
	if created:
		UserProfile.objects.create(user=instance)

post_save.connect(create_user_profile, sender=User)

# TODO Chatrooms : title, slug, comments--- allowedusers, files---, logs--- ('user', 'action', 'date')

# TODO: Quotes: title, description, optionals--- ('title', 'description', 'price', 'term' - hourly, monthly, quarterly, bianually, yearly), etc. TODO