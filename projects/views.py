# Create your views here.
from django.views.generic.simple import direct_to_template
from django.http import HttpResponse, Http404
from django.shortcuts import render_to_response, get_object_or_404
from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.core.serializers import serialize
from django.utils.simplejson import loads
from django.db.models.query import QuerySet
from django.db.models.fields.files import FieldFile, ImageFieldFile
from django.template.defaultfilters import slugify, date
from django.contrib import messages

from django.db.models.base import ModelBase

# code below is needed for slugify
#import os
#os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'
#from django.template.defaultfilters import slugify

# random
from random import Random
import uuid
# regular expressions
import re
# timezones
import pytz
# mandrill
import mandrill

from projects.models import *

# helper that will return the project according to a slug or id, if the user has permissions to access it
def get_project_if_youre_allowed(request, project_slug_or_id):
	if request.user.is_staff:
		if is_string(project_slug_or_id):
			project = get_object_or_404(Project, slug=project_slug_or_id, archived=False)
		else:
			project = get_object_or_404(Project, pk=project_slug_or_id, archived=False)
	else:
		if is_string(project_slug_or_id):
			project = get_object_or_404(Project, slug=project_slug_or_id, archived=False, company__users__id=request.user.id)
		else:
			project = get_object_or_404(Project, pk=project_slug_or_id, archived=False, company__users__id=request.user.id)
	return project

# helper to check if a variable is a string or an id
def is_string(mixed):
	if isinstance(mixed, dict):
		return True
	elif isinstance(mixed, basestring):
		return True
	elif isinstance(mixed, int):
		return False
	else:
		return None

# helper to generate random hash
def get_random_hash(length):
	uid = uuid.uuid4()
	return uid.hex

# helper to generate a unique slug
def unique_slug(itemModel, value):
	slug = slugify(value)

	# the following gets all existing slug values
	allSlugs = [sl.values()[0] for sl in itemModel.objects.values('slug')]
	if slug in allSlugs:
		counterFinder = re.compile(r'-\d+$')
		counter = 1
		slug = "%s-%i" % (slug, counter)

		while slug in allSlugs:
			slug = re.sub(counterFinder,"-%i" % counter, slug)
			counter += 1

		return slug

	return slug

# Get All Files Related to an Object
def get_all_files_related(object_type, object_id):
	related_files = []

	related_files_query = File.objects.filter(original_object=object_type, original_object_id=int(object_id))

	for related_file in related_files_query:
		parsedFile = {
			'id': related_file.id,
			'url': related_file.file.url,
			'info_url': related_file.get_absolute_url(),
			'file': str(related_file.file),
			'name': related_file.name,
		}

		related_files.append(parsedFile)

	return related_files

# helper for JSON encoding for the non-Django models
def json_custom_encoding(obj):
	if hasattr(obj, 'isoformat'):# Date.datetime
		return obj.isoformat()

	if isinstance(obj, QuerySet):
		return simplejson.loads(serialize('json', obj))
		# TODO: (maybe) iterate through obj, using obj[index].model ("project.task") and obj[index].pk (1), obj.__class__.__name__

	elif isinstance(obj, ImageFieldFile):
		if obj.url:
			return obj.url
		else:
			return ''

	elif isinstance(obj, FieldFile):
		if obj.url:
			return obj.url
		else:
			return ''

	elif isinstance(obj, Project):
		return {
			'id': obj.id,
			'name': obj.name,
			'slug': obj.slug,
			'description': obj.description,
			'archived': obj.archived,
			'url': obj.get_absolute_url(),
		}
	elif isinstance(obj, Milestone):
		return {
			'id': obj.id,
			'project': obj.project,
			'name': obj.name,
			'slug': obj.slug,
			'date': obj.date,
			'due_date': obj.due_date,
			'description': obj.description,
			'completed': obj.completed,
			'completed_date': obj.completed_date,
			'url': obj.get_absolute_url(),
		}
	elif isinstance(obj, Discussion):
		return {
			'id': obj.id,
			'project': obj.project,
			'title': obj.title,
			'slug': obj.slug,
			'date': obj.date,
			'content': obj.content,
			'author': obj.author,
			'private': obj.private,
			'completed': obj.completed,
			'completed_date': obj.completed_date,
			'url': obj.get_absolute_url(),
			'comments': obj.comments.all(),# TODO: Convert to use User-like parsing
			'files': get_all_files_related('d', obj.id),
		}
	elif isinstance(obj, DiscussionComment):
		return {
			'id': obj.id,
			'discussion': obj.discussion,
			'date': obj.date,
			'content': obj.content,
			'author': obj.author,
			'files': get_all_files_related('dc', obj.id),
		}
	elif isinstance(obj, List):
		return {
			'id': obj.id,
			'project': obj.project,
			'name': obj.name,
			'slug': obj.slug,
			'milestone': obj.milestone,
			'date': obj.date,
			'description': obj.description,
			'author': obj.author,
			'private': obj.private,
			'completed': obj.completed,
			'url': obj.get_absolute_url(),
			'tasks': obj.tasks.all(),# TODO: Convert to use User-like parsing
			'tasks_incomplete': obj.tasks.filter(completed=False),# TODO: Convert to use User-like parsing
			'tasks_complete': obj.tasks.filter(completed=True),# TODO: Convert to use User-like parsing
		}
	elif isinstance(obj, Task):
		return {
			'id': obj.id,
			'title': obj.title,
			'slug': obj.slug,
			'list': obj.list,
			'description': obj.description,
			'date': obj.date,
			'due_date': obj.due_date,
			'priority': obj.priority,
			'author': obj.author,
			'responsible': obj.responsible,
			'completed': obj.completed,
			'comments': obj.comments.all(),# TODO: Convert to use User-like parsing
			'url': obj.get_absolute_url(),
			'files': get_all_files_related('t', obj.id),
		}
	elif isinstance(obj, TaskComment):
		return {
			'id': obj.id,
			'task': obj.task,
			'date': obj.date,
			'content': obj.content,
			'author': obj.author,
			'files': get_all_files_related('tc', obj.id),
		}
	elif isinstance(obj, File):
		return {
			'id': obj.id,
			'project': obj.project,
			'name': obj.name,
			'slug': obj.slug,
			'file': obj.file,
			'date': obj.date,
			'author': obj.author,
			'original_object': obj.original_object,
			'original_object_id': obj.original_object_id,
			'description': obj.description,
			'private': obj.private,
			'url': obj.get_absolute_url(),
		}
	elif isinstance(obj, FileComment):
		return {
			'id': obj.id,
			'file': obj.file,
			'date': obj.date,
			'content': obj.content,
			'author': obj.author,
			'files': get_all_files_related('fc', obj.id),
		}
	elif isinstance(obj, Company):
		return {
			'id': obj.id,
			'name': obj.name,
			'slug': obj.slug,
			'url': obj.url,
			'users': obj.users.all(),# TODO: Convert to use User-like parsing
		}
	elif isinstance(obj, User):
		parsedUser = {
			'id': obj.id,
			'username': obj.username,
			'first_name': obj.first_name,
			'last_name': obj.last_name,
			'email': obj.email,
			'profile': get_user_profile(obj),
			'company': {},
		}

		if obj.companies.count() > 0:
			originalObject = obj.companies.all()
			originalObject = originalObject[0]

			parsedCompany = get_object_or_404(Company, pk=originalObject.id)

			parsedUser.update( company = parsedCompany )

		return parsedUser
	elif isinstance(obj, UserProfile):
		parsedProfile = {
			'avatar': obj.getAvatar(),
			'url': obj.url,
			'phone': obj.phone,
		}
		return parsedProfile
	else:
		raise TypeError, "Object of type %s with value of %s is not JSON serializable" % ( type(obj), repr(obj) )

# helper to check permissions
def is_user_allowed_to(user, action, item):
	if user.is_staff:
		return True

	if item.__class__.__name__ == 'List' or item.__class__.__name__ == 'Discussion' or item.__class__.__name__ == 'Task' or item.__class__.__name__ == 'File':
		if action == 'update' or action == 'delete':
			if user.id == item.author.id:
				return True

			# Is the author in a company?
			if item.author.companies.count() > 0:

				# Now get the companies in which the current user is in and see if there's a match
				companies = Company.objects.filter(users__id=user.id)

				for author_company in item.author.companies.all():
					for user_company in companies:
						if user_company.id == author_company.id:
							return True

	if item.__class__.__name__ == 'DiscussionComment' or item.__class__.__name__ == 'TaskComment' or item.__class__.__name__ == 'FileComment':
		if action == 'update' or action == 'delete':
			if user.id == item.author.id:
				return True

	return False


# helper to get current timezone
def get_user_dependent_current_timezone(request):
	if get_user_profile(request.user).timezone:
		return get_user_profile(request.user).timezone
	return settings.TIME_ZONE

# helper to send emails
def send_an_email(name, email, subject, content):
	m = mandrill.Mandrill(settings.MANDRILL_API_KEY)

	msg = {
		'subject': subject,
		'html': content,
		'from_name': settings.ADMINS[0][0],
		'from_email': settings.ADMINS[0][1],
		'to': [
			{
				'name': name,
				'email': email,
			},
		],
		'tags': [
			'unity'
		],
	}

	m.messages.send(msg)

# API views
from projects.api import *

# AJAX views
from projects.ajax import *

# Views
@login_required()
def dashboard(request):
	if request.user.is_staff:
		projects_list = Project.objects.filter(archived=False).order_by('-date')
	else:
		projects_list = Project.objects.filter(archived=False, company__users__id=request.user.id).order_by('-date')

	current_menu = 'dashboard';

	return render_to_response('projects/dashboard.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'projects': projects_list,
	})

@login_required()
def projects(request):
	if request.user.is_staff:
		projects_list = Project.objects.filter(archived=False).order_by('-date')
	else:
		projects_list = Project.objects.filter(archived=False, company__users__id=request.user.id).order_by('-date')

	current_menu = 'projects';

	return render_to_response('projects/projects.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'projects': projects_list,
	})

@login_required()
def project(request, project_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	current_menu = 'projects';

	return render_to_response('projects/project.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
	})

@login_required()
def milestones(request, project_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	current_menu = 'projects';

	return render_to_response('projects/milestones.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
	})

@login_required()
def milestone(request, project_slug, milestone_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	milestone = get_object_or_404(Milestone, slug=milestone_slug, project__id=project.id)

	current_menu = 'projects';

	return render_to_response('projects/milestone.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
		'milestone': milestone,
	})

@login_required()
def discussions(request, project_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	current_menu = 'projects';

	return render_to_response('projects/discussions.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
	})

@login_required()
def discussion(request, project_slug, discussion_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	if request.user.is_staff:
		discussion = get_object_or_404(Discussion, slug=discussion_slug, project__id=project.id)
	else:
		discussion = get_object_or_404(Discussion, slug=discussion_slug, project__id=project.id, private=False)

	files = get_all_files_related('d', discussion.id)

	current_menu = 'projects';

	return render_to_response('projects/discussion.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
		'discussion': discussion,
		'files': files,
	})

@login_required()
def lists(request, project_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	current_menu = 'projects';

	return render_to_response('projects/lists.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
	})

@login_required()
def list(request, project_slug, list_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	if request.user.is_staff:
		list = get_object_or_404(List, slug=list_slug, project__id=project.id)
	else:
		list = get_object_or_404(List, slug=list_slug, project__id=project.id, private=False)

	current_menu = 'projects';

	return render_to_response('projects/list.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
		'list': list,
	})

@login_required()
def task(request, project_slug, list_slug, task_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	if request.user.is_staff:
		list = get_object_or_404(List, slug=list_slug, project__id=project.id)
	else:
		list = get_object_or_404(List, slug=list_slug, project__id=project.id, private=False)

	task = get_object_or_404(Task, slug=task_slug, list__id=list.id)
	files = get_all_files_related('t', task.id)

	current_menu = 'projects';

	return render_to_response('projects/task.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
		'list': list,
		'task': task,
		'files': files,
	})

@login_required()
def tasks(request):
	tasks_list = Task.objects.filter(responsible__id=request.user.id).order_by('-date')

	current_menu = 'tasks';

	return render_to_response('projects/tasks.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'tasks': tasks_list,
	})

@login_required()
def files(request, project_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	current_menu = 'projects';

	return render_to_response('projects/files.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
	})

@login_required()
def file(request, project_slug, file_slug):
	project = get_project_if_youre_allowed(request, project_slug)

	if request.user.is_staff:
		file = get_object_or_404(File, slug=file_slug, project__id=project.id)
	else:
		file = get_object_or_404(File, slug=file_slug, project__id=project.id, private=False)

	current_menu = 'projects';

	if file.original_object == 'd':
		relatedObjectName = 'Discussion'
		relatedObject = get_object_or_404(Discussion, pk=file.original_object_id)
		
	elif file.original_object == 'dc':
		relatedObjectName = 'Discussion Comment'
		relatedObject = get_object_or_404(DiscussionComment, pk=file.original_object_id)

	elif file.original_object == 't':
		relatedObjectName = 'Task'
		relatedObject = get_object_or_404(Task, pk=file.original_object_id)

	elif file.original_object == 'tc':
		relatedObjectName = 'Task Comment'
		relatedObject = get_object_or_404(TaskComment, pk=file.original_object_id)

	elif file.original_object == 'fc':
		relatedObjectName = 'File Comment'
		relatedObject = get_object_or_404(FileComment, pk=file.original_object_id)

	return render_to_response('projects/file.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'project': project,
		'file': file,
		'relatedObjectName': relatedObjectName,
		'relatedObject': relatedObject,
	})

@login_required()
def companies(request):
	if request.user.is_staff:
		companies_list = Company.objects.all().order_by('-name')
	else:
		raise Http404

	current_menu = 'companies';

	return render_to_response('projects/companies.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'companies': companies_list,
	})

@login_required()
def company(request, company_slug):
	if request.user.is_staff:
		company = get_object_or_404(Company, slug=company_slug)
	else:
		company = get_object_or_404(Company, slug=company_slug, users__id=request.user.id)

	current_menu = 'companies';

	return render_to_response('projects/company.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'company': company,
	})

@login_required()
def calendar(request):
	if request.user.is_staff:
		milestones_list = Milestone.objects.filter(project__archived=False).order_by('-due_date')
	else:
		milestones_list = Milestone.objects.filter(project__archived=False, project__company__users__id=request.user.id).order_by('-due_date')

	current_menu = 'calendar';

	return render_to_response('projects/calendar.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'milestones': milestones_list,
	})

@login_required()
def user(request, username):
	user = get_object_or_404(User, username=username)

	current_menu = 'users';

	return render_to_response('registration/user.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'viewed_user': user,
	})

@login_required()
def profile(request):
	current_menu = 'profile';

	return render_to_response('registration/profile.html', {
		'main_url': settings.MAIN_URL,
		'current_timezone': get_user_dependent_current_timezone(request),
		'current_menu': current_menu,
		'user': request.user,
		'profile': get_user_profile(request.user),
		'messages': messages.get_messages(request),
		'timezones': pytz.common_timezones
	})