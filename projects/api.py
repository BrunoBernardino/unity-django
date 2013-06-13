# Create your ajax views here.
from django.views.generic.simple import direct_to_template
from django.http import HttpResponse, Http404
from django.shortcuts import render_to_response, get_object_or_404
from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.utils import simplejson, timezone
from django.core.serializers import serialize
from django.template.loader import get_template
from django.template import Context
from itertools import chain

from projects.models import *

from projects.views import get_project_if_youre_allowed, json_custom_encoding, unique_slug, is_user_allowed_to, send_an_email

@login_required()
def projects_api(request, id = False):
	return_data = {}

	if request.method == 'GET':# read
		if id:
			project = get_project_if_youre_allowed(request, id)

			return_data = project
		else:
			if request.user.is_staff:
				projects = list( Project.objects.filter(archived=False).order_by('-date') )
			else:
				projects = list( Project.objects.filter(archived=False, company__users__id=request.user.id).order_by('-date') ) 

			return_data = projects
	elif request.method == 'POST':# create
		if not request.user.is_staff:
			raise Http404

		requestData = simplejson.loads(request.body)

		if requestData.get('company', None) and requestData.get('company').get('id', None):
			company = get_object_or_404(Company, pk=requestData.get('company').get('id'))
		else:
			company = None

		project = Project(
			name = requestData.get('name'),
			slug = unique_slug( Project, requestData.get('name') ),
			company = company,
			description = requestData.get('description')
		)

		project.save()

		return_data = project
	elif request.method == 'PUT':# update
		if not request.user.is_staff:
			raise Http404

		requestData = simplejson.loads(request.body)

		project = get_object_or_404(Project, pk=id)

		project.name = requestData.get('name')
		project.description = requestData.get('description')
		project.archived = requestData.get('archived')

		if requestData.get('company', None) and requestData.get('company').get('id', None):
			company = get_object_or_404(Company, pk=requestData.get('company').get('id'))
			project.company = company

		project.save()

		return_data = project
	elif request.method == 'DELETE':# delete
		if not request.user.is_staff:
			raise Http404

		project = get_project_if_youre_allowed(request, id)

		project.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def milestones_api(request, id = False):
	return_data = {}

	if request.method == 'GET':# read
		if id:
			milestone = get_object_or_404(Milestone, pk=id)

			return_data = milestone
		elif request.GET.get('project_id', None):
			project = get_project_if_youre_allowed(request, int(request.GET.get('project_id')))

			if request.GET.get('incompleted_only', None):
				theMilestones = project.milestones.filter(completed=False).order_by('-date')
			elif request.GET.get('completed_only', None):
				theMilestones = project.milestones.filter(completed=True).order_by('-date')
			else:
				theMilestones = project.milestones.all().order_by('-date')

			milestones = list( theMilestones )

			return_data = milestones
		else:
			raise Http404
	elif request.method == 'POST':# create
		requestData = simplejson.loads(request.body)

		project = get_project_if_youre_allowed(request, int(requestData.get('project').get('id')))

		milestone = Milestone(
			project = project,
			name = requestData.get('name'),
			slug = unique_slug( Milestone, requestData.get('name') ),
			due_date = requestData.get('due_date'),
			description = requestData.get('description'),
		)

		milestone.save()

		return_data = milestone
	elif request.method == 'PUT':# update
		if not request.user.is_staff:
			raise Http404

		requestData = simplejson.loads(request.body)

		milestone = get_object_or_404(Milestone, pk=id)

		previousCompletedStatus = milestone.completed

		milestone.name = requestData.get('name')
		milestone.due_date = requestData.get('due_date')
		milestone.description = requestData.get('description')
		milestone.completed = requestData.get('completed', False)

		# If the milestone is complete, complete all lists and tasks
		if milestone.completed:
			milestone.lists.all().update(completed=True)

			for theList in milestone.lists.all():
				theList.tasks.all().update(completed=True)

				if not previousCompletedStatus:
					theList.tasks.all().update(completed_date=timezone.now())

			if not previousCompletedStatus:
				milestone.completed_date = timezone.now()

				milestone.lists.all().update(completed_date=timezone.now())

		milestone.save()

		return_data = milestone
	elif request.method == 'DELETE':# delete
		if not request.user.is_staff:
			raise Http404

		milestone = get_object_or_404(Milestone, pk=id)

		milestone.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def discussions_api(request, id = False):
	return_data = {}

	if request.method == 'GET':# read
		if id:
			if request.user.is_staff:
				discussion = get_object_or_404(Discussion, pk=id)
			else:
				discussion = get_object_or_404(Discussion, pk=id, private=False)

			return_data = discussion
		elif request.GET.get('project_id', None):
			project = get_project_if_youre_allowed(request, int(request.GET.get('project_id')))

			if request.user.is_staff:
				if request.GET.get('incompleted_only', None):
					theDiscussions = project.discussions.filter(completed=False).order_by('-date')
				elif request.GET.get('completed_only', None):
					theDiscussions = project.discussions.filter(completed=True).order_by('-date')
				else:
					theDiscussions = project.discussions.all().order_by('-date')
			else:
				if request.GET.get('incompleted_only', None):
					theDiscussions = project.discussions.filter(completed=False, private=False).order_by('-date')
				elif request.GET.get('completed_only', None):
					theDiscussions = project.discussions.filter(completed=True, private=False).order_by('-date')
				else:
					theDiscussions = project.discussions.filter(private=False).order_by('-date')

			discussions = list( theDiscussions )

			return_data = discussions
		else:
			raise Http404
	elif request.method == 'POST':# create
		requestData = simplejson.loads(request.body)

		project = get_project_if_youre_allowed(request, int(requestData.get('project').get('id')))

		author = get_object_or_404(User, pk=request.user.id)

		discussion = Discussion(
			project = project,
			title = requestData.get('title'),
			slug = unique_slug( Discussion, requestData.get('title') ),
			author = author,
			content = requestData.get('content'),
			private = requestData.get('private'),
		)

		if not request.user.is_staff:
			discussion.private = False

		discussion.save()

		# Email Notifications
		# Create Email Content & Subject
		subject = 'New Discussion Posted on %s by %s' % ( project.name, author.get_full_name() )
		template = get_template('emails/discussion-new.html')

		# Send email to staff
		staff_users = User.objects.filter(is_staff=True).exclude(pk=author.id).exclude(pk=1) # excluding author and admin
		for staff_user in staff_users:
			variables = Context({
				'main_url': settings.MAIN_URL,
				'author': author,
				'project': project,
				'discussion': discussion,
				'user': staff_user,
			})
			content = template.render(variables)

			send_an_email(staff_user.get_full_name(), staff_user.email, subject, content)

		# Send email to clients if the discussion is not private
		if (not discussion.private) and project.company:
			clients = User.objects.filter(companies__id=project.company.id).exclude(pk=author.id).exclude(pk=1) # excluding author and admin

			for client in clients:
				variables = Context({
					'main_url': settings.MAIN_URL,
					'author': author,
					'project': project,
					'discussion': discussion,
					'user': client,
				})
				content = template.render(variables)

				send_an_email(client.get_full_name(), client.email, subject, content)

		return_data = discussion
	elif request.method == 'PUT':# update
		requestData = simplejson.loads(request.body)

		discussion = get_object_or_404(Discussion, pk=id)

		previousCompletedStatus = discussion.completed

		if not is_user_allowed_to(request.user, 'update', discussion):
			raise Http404

		discussion.title = requestData.get('title')
		discussion.content = requestData.get('content')
		discussion.private = requestData.get('private')
		discussion.completed = requestData.get('completed', False)

		if not request.user.is_staff:
			discussion.private = False

		if discussion.completed and not previousCompletedStatus:
			discussion.completed_date = timezone.now()

		discussion.save()

		return_data = discussion
	elif request.method == 'DELETE':# delete
		discussion = get_object_or_404(Discussion, pk=id)

		if not is_user_allowed_to(request.user, 'delete', discussion):
			raise Http404

		discussion.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def discussion_comments_api(request, id = False):# TODO: Consider File upload
	return_data = {}

	if request.method == 'GET':# read
		if id:
			if request.user.is_staff:
				discussion_comment = get_object_or_404(DiscussionComment, pk=id)
			else:
				discussion_comment = get_object_or_404(DiscussionComment, pk=id, discussion__private=False)

			return_data = discussion_comment
		elif request.GET.get('discussion_id', None):
			if request.user.is_staff:
				discussion = get_object_or_404(Discussion, pk=request.GET.get('discussion_id'))
			else:
				discussion = get_object_or_404(Discussion, pk=request.GET.get('discussion_id'), private=False)

			discussion_comments = list( discussion.comments.all() )

			return_data = discussion_comments
		else:
			raise Http404
	elif request.method == 'POST':# create
		requestData = simplejson.loads(request.body)

		discussion = get_object_or_404(Discussion, pk=requestData.get('discussion').get('id'))

		# This just checks if the discussion is from an allowed project
		project = get_project_if_youre_allowed(request, discussion.project.id)

		author = get_object_or_404(User, pk=request.user.id)

		discussion_comment = DiscussionComment(
			discussion = discussion,
			author = author,
			content = requestData.get('content')
		)

		discussion_comment.save()

		# Email Notifications
		# Create Email Content & Subject
		subject = 'New Discussion Comment Posted on %s by %s' % ( project.name, author.get_full_name() )
		template = get_template('emails/discussion-comment-new.html')

		# Send email to staff
		staff_users = User.objects.filter(is_staff=True).exclude(pk=author.id).exclude(pk=1) # excluding author and admin
		for staff_user in staff_users:
			variables = Context({
				'main_url': settings.MAIN_URL,
				'author': author,
				'project': project,
				'discussion': discussion,
				'discussion_comment': discussion_comment,
				'user': staff_user,
			})
			content = template.render(variables)

			send_an_email(staff_user.get_full_name(), staff_user.email, subject, content)

		# Send email to clients if the discussion is not private
		if (not discussion.private) and project.company:
			clients = User.objects.filter(companies__id=project.company.id).exclude(pk=author.id).exclude(pk=1) # excluding author and admin

			for client in clients:
				variables = Context({
					'main_url': settings.MAIN_URL,
					'author': author,
					'project': project,
					'discussion': discussion,
					'discussion_comment': discussion_comment,
					'user': client,
				})
				content = template.render(variables)

				send_an_email(client.get_full_name(), client.email, subject, content)

		return_data = discussion_comment
	elif request.method == 'PUT':# update
		requestData = simplejson.loads(request.body)

		discussion_comment = get_object_or_404(DiscussionComment, pk=id)

		if not is_user_allowed_to(request.user, 'update', discussion_comment):
			raise Http404

		discussion_comment.content = requestData.get('content')

		discussion_comment.save()

		return_data = discussion_comment
	elif request.method == 'DELETE':# delete
		discussion_comment = get_object_or_404(DiscussionComment, pk=id)

		if not is_user_allowed_to(request.user, 'delete', discussion_comment):
			raise Http404

		discussion_comment.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def lists_api(request, id = False):
	return_data = {}

	if request.method == 'GET':# read
		if id:
			if request.user.is_staff:
				theList = get_object_or_404(List, pk=id)
			else:
				theLists = get_object_or_404(List, pk=id, private=False)

			return_data = theList
		elif request.GET.get('project_id', None):
			project = get_project_if_youre_allowed(request, int(request.GET.get('project_id')))

			if request.user.is_staff:
				if request.GET.get('incompleted_only', None):
					theLists = project.lists.filter(completed=False).order_by('-date')
				elif request.GET.get('completed_only', None):
					theLists = project.lists.filter(completed=True).order_by('-date')
				else:
					theLists = project.lists.all().order_by('-date')
			else:
				if request.GET.get('incompleted_only', None):
					theLists = project.lists.filter(completed=False, private=False).order_by('-date')
				elif request.GET.get('completed_only', None):
					theLists = project.lists.filter(completed=True, private=False).order_by('-date')
				else:
					theLists = project.lists.filter(private=False).order_by('-date')

			lists = list( theLists )

			return_data = lists
		else:
			raise Http404
	elif request.method == 'POST':# create
		requestData = simplejson.loads(request.body)

		project = get_project_if_youre_allowed(request, int(requestData.get('project').get('id')))

		if requestData.get('milestone', None) and requestData.get('milestone').get('id', None):
			milestone = get_object_or_404(Milestone, pk=requestData.get('milestone').get('id'))
		else:
			milestone = None

		author = get_object_or_404(User, pk=request.user.id)

		theList = List(
			project = project,
			milestone = milestone,
			name = requestData.get('name'),
			slug = unique_slug( List, requestData.get('name') ),
			author = author,
			private = requestData.get('private'),
			description = requestData.get('description'),
		)

		if not request.user.is_staff:
			theList.private = False

		theList.save()

		return_data = theList
	elif request.method == 'PUT':# update
		requestData = simplejson.loads(request.body)

		theList = get_object_or_404(List, pk=id)

		if not is_user_allowed_to(request.user, 'update', theList):
			raise Http404

		previousCompletedStatus = theList.completed

		theList.name = requestData.get('name')
		theList.description = requestData.get('description')
		theList.private = requestData.get('private')
		theList.completed = requestData.get('completed', False)

		if not request.user.is_staff:
			theList.private = False

		if requestData.get('milestone', None) and requestData.get('milestone').get('id', None):
			milestone = get_object_or_404(Milestone, pk=requestData.get('milestone').get('id'))
			theList.milestone = milestone
		else:
			theList.milestone = None

		# If the list is complete, complete all tasks
		if theList.completed:
			theList.tasks.all().update(completed=True)

			if not previousCompletedStatus:
				theList.completed_date = timezone.now()

				theList.tasks.all().update(completed_date=timezone.now())

		theList.save()

		return_data = theList
	elif request.method == 'DELETE':# delete
		theList = get_object_or_404(List, pk=id)

		if not is_user_allowed_to(request.user, 'delete', theList):
			raise Http404

		theList.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def tasks_api(request, id = False):
	return_data = {}

	if request.method == 'GET':# read
		if id:
			if request.user.is_staff:
				task = get_object_or_404(Task, pk=id)
			else:
				task = get_object_or_404(Task, pk=id, list__private=False)

			return_data = task
		elif request.GET.get('list_id', None):
			if request.user.is_staff:
				theList = get_object_or_404(List, pk=request.GET.get('list_id'))
			else:
				theList = get_object_or_404(List, pk=request.GET.get('list_id'), private=False)

			if request.GET.get('incompleted_only', None):
				if request.GET.get('mine_only', None):
					theTasks = theList.tasks.filter(completed=False, responsible=request.user).order_by('priority', '-date')
				else:
					theTasks = theList.tasks.filter(completed=False).order_by('priority', '-date')
			elif request.GET.get('completed_only', None):
				if request.GET.get('mine_only', None):
					theTasks = theList.tasks.filter(completed=True, responsible=request.user).order_by('priority', '-date')
				else:
					theTasks = theList.tasks.filter(completed=True).order_by('priority', '-date')
			else:
				if request.GET.get('mine_only', None):
					theTasks = theList.tasks.filter(responsible=request.user).order_by('priority', '-date')
				else:
					theTasks = theList.tasks.all().order_by('priority', '-date')

			tasks = list( theTasks )

			return_data = tasks
		else:
			raise Http404
	elif request.method == 'POST':# create
		requestData = simplejson.loads(request.body)

		theList = get_object_or_404(List, pk=requestData.get('list').get('id'))

		# This just checks if the list is from an allowed project
		project = get_project_if_youre_allowed(request, theList.project.id)

		if requestData.get('responsible', None) and requestData.get('responsible').get('id', None):
			responsible = get_object_or_404(User, pk=requestData.get('responsible').get('id'))
		else:
			responsible = None

		author = get_object_or_404(User, pk=request.user.id)

		task = Task(
			list = theList,
			title = requestData.get('title'),
			slug = unique_slug( Task, requestData.get('title') ),
			responsible = responsible,
			author = author,
			description = requestData.get('description')
		)

		if requestData.get('priority', None):
			task.priority = int( requestData.get('priority') )

		if requestData.get('due_date', None):
			task.due_date = requestData.get('due_date', None)
		else:
			task.due_date = None

		task.save()

		if task.responsible:
			# Email Notifications
			# Create Email Content & Subject
			subject = 'New Task Assigned to You on %s by %s' % ( project.name, author.get_full_name() )
			template = get_template('emails/task-assigned.html')

			# Send email to responsible user
			variables = Context({
				'main_url': settings.MAIN_URL,
				'author': author,
				'project': project,
				'task': task,
				'user': task.responsible,
			})
			content = template.render(variables)

			send_an_email(task.responsible.get_full_name(), task.responsible.email, subject, content)

		return_data = task
	elif request.method == 'PUT':# update
		requestData = simplejson.loads(request.body)

		task = get_object_or_404(Task, pk=id)

		if not is_user_allowed_to(request.user, 'update', task):
			raise Http404

		previousCompletedStatus = task.completed
		previousResponsible = task.responsible

		task.title = requestData.get('title')
		task.description = requestData.get('description')
		task.priority = requestData.get('priority')
		task.completed = requestData.get('completed', False)

		if requestData.get('due_date', None):
			task.due_date = requestData.get('due_date')
		else:
			task.due_date = None

		if requestData.get('list', None) and requestData.get('list').get('id', None):
			theList = get_object_or_404(List, pk=requestData.get('list').get('id'))
			task.list = theList
		else:
			task.list = None

		if requestData.get('responsible', None) and requestData.get('responsible').get('id', None):
			responsible = get_object_or_404(User, pk=requestData.get('responsible').get('id'))
			task.responsible = responsible
		else:
			task.responsible = None

		if task.completed and not previousCompletedStatus:
			task.completed_date = timezone.now()

		task.save()

		if task.responsible and previousResponsible != task.responsible:
			# Email Notifications
			# Create Email Content & Subject
			subject = 'New Task Assigned to You on %s by %s' % ( task.list.project.name, request.user.get_full_name() )
			template = get_template('emails/task-assigned.html')

			# Send email to responsible user
			variables = Context({
				'main_url': settings.MAIN_URL,
				'author': request.user,
				'project': task.list.project,
				'task': task,
				'user': task.responsible,
			})
			content = template.render(variables)

			send_an_email(task.responsible.get_full_name(), task.responsible.email, subject, content)

		return_data = task
	elif request.method == 'DELETE':# delete
		task = get_object_or_404(Task, pk=id)

		if not is_user_allowed_to(request.user, 'delete', task):
			raise Http404

		task.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def task_comments_api(request, id = False):# TODO: Consider File upload
	return_data = {}

	if request.method == 'GET':# read
		if id:
			if request.user.is_staff:
				task_comment = get_object_or_404(TaskComment, pk=id)
			else:
				task_comment = get_object_or_404(TaskComment, pk=id, task__list__private=False)

			return_data = task_comment
		elif request.GET.get('task_id', None):
			if request.user.is_staff:
				task = get_object_or_404(Task, pk=request.GET.get('task_id'))
			else:
				task = get_object_or_404(Task, pk=request.GET.get('task_id'), list__private=False)

			task_comments = list( task.comments.all() )

			return_data = task_comments
		else:
			raise Http404
	elif request.method == 'POST':# create
		requestData = simplejson.loads(request.body)

		task = get_object_or_404(Task, pk=requestData.get('task').get('id'))

		# This just checks if the task is from an allowed project
		project = get_project_if_youre_allowed(request, task.list.project.id)

		author = get_object_or_404(User, pk=request.user.id)

		task_comment = TaskComment(
			task = task,
			author = author,
			content = requestData.get('content')
		)

		task_comment.save()

		# Email Notifications
		# Create Email Content & Subject
		subject = 'New Task Comment Posted on %s by %s' % ( project.name, author.get_full_name() )
		template = get_template('emails/task-comment-new.html')

		# Send email to staff
		staff_users = User.objects.filter(is_staff=True).exclude(pk=author.id).exclude(pk=1) # excluding author and admin
		for staff_user in staff_users:
			variables = Context({
				'main_url': settings.MAIN_URL,
				'author': author,
				'project': project,
				'task': task,
				'task_comment': task_comment,
				'user': staff_user,
			})
			content = template.render(variables)

			send_an_email(staff_user.get_full_name(), staff_user.email, subject, content)

		# Send email to clients if the task's list is not private
		if (not task.list.private) and project.company:
			clients = User.objects.filter(companies__id=project.company.id).exclude(pk=author.id).exclude(pk=1) # excluding author and admin

			for client in clients:
				variables = Context({
					'main_url': settings.MAIN_URL,
					'author': author,
					'project': project,
					'task': task,
					'task_comment': task_comment,
					'user': client,
				})
				content = template.render(variables)

				send_an_email(client.get_full_name(), client.email, subject, content)

		return_data = task_comment
	elif request.method == 'PUT':# update
		requestData = simplejson.loads(request.body)

		task_comment = get_object_or_404(TaskComment, pk=id)

		if not is_user_allowed_to(request.user, 'update', task_comment):
			raise Http404

		task_comment.content = requestData.get('content')

		task_comment.save()

		return_data = task_comment
	elif request.method == 'DELETE':# delete
		task_comment = get_object_or_404(TaskComment, pk=id)

		if not is_user_allowed_to(request.user, 'delete', task_comment):
			raise Http404

		task_comment.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def files_api(request, id = False):# TODO: Consider File upload
	return_data = {}

	if request.method == 'GET':# read
		if id:
			if request.user.is_staff:
				theFile = get_object_or_404(File, pk=id)
			else:
				theFile = get_object_or_404(File, pk=id, private=False)

			return_data = theFile
		elif request.GET.get('project_id', None):
			project = get_project_if_youre_allowed(request, int(request.GET.get('project_id')))

			if request.user.is_staff:
				files = list( project.files.all() )
			else:
				files = list( project.files.filter(private=False) )

			return_data = files
		else:
			raise Http404
	elif request.method == 'POST':# create
		requestData = simplejson.loads(request.body)

		project = get_project_if_youre_allowed(request, int(requestData.get('project').get('id')))

		author = get_object_or_404(User, pk=request.user.id)

		theFile = File(
			project = project,
			name = requestData.get('name'),
			slug = unique_slug( File, requestData.get('name') ),
			file = requestData.get('file'),# TODO: Check if FILES has this
			author = author,
			original_object = requestData.get('original_object'),
			original_object_id = requestData.get('original_object_id'),
			description = requestData.get('description'),
			private = requestData.get('private')
		)

		if not request.user.is_staff:
			theFile.private = False

		theFile.save()

		return_data = theFile
	elif request.method == 'PUT':# update
		requestData = simplejson.loads(request.body)

		theFile = get_object_or_404(File, pk=id)

		if not is_user_allowed_to(request.user, 'update', theFile):
			raise Http404

#		theFile.name = requestData.get('name')
#		theFile.file = requestData.get('file')# TODO: Check if FILES has this
		theFile.description = requestData.get('description')
		

		theFile.save()

		return_data = theFile
	elif request.method == 'DELETE':# delete
		theFile = get_object_or_404(File, pk=id)

		if not is_user_allowed_to(request.user, 'delete', theFile):
			raise Http404

		theFile.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def file_comments_api(request, id = False):# TODO: Consider File upload
	return_data = {}

	if request.method == 'GET':# read
		if id:
			if request.user.is_staff:
				file_comment = get_object_or_404(FileComment, pk=id)
			else:
				file_comment = get_object_or_404(FileComment, pk=id, file__private=False)

			return_data = file_comment
		elif request.GET.get('file_id', None):
			theFile = get_object_or_404(File, pk=request.GET.get('file_id'))

			file_comments = list( theFile.comments.all() )

			return_data = file_comments
		else:
			raise Http404
	elif request.method == 'POST':# create
		requestData = simplejson.loads(request.body)

		if request.user.is_staff:
			theFile = get_object_or_404(File, pk=requestData.get('file').get('id'))
		else:
			theFile = get_object_or_404(File, pk=requestData.get('file').get('id'), private=False)

		# This just checks if the file is from an allowed project
		project = get_project_if_youre_allowed(request, theFile.project.id)

		author = get_object_or_404(User, pk=request.user.id)

		file_comment = FileComment(
			file = theFile,
			author = author,
			content = requestData.get('content')
		)

		file_comment.save()

		# Email Notifications
		# Create Email Content & Subject
		subject = 'New File Comment Posted on %s by %s' % ( project.name, author.get_full_name() )
		template = get_template('emails/file-comment-new.html')

		# Send email to staff
		staff_users = User.objects.filter(is_staff=True).exclude(pk=author.id).exclude(pk=1) # excluding author and admin
		for staff_user in staff_users:
			variables = Context({
				'main_url': settings.MAIN_URL,
				'author': author,
				'project': project,
				'file': theFile,
				'file_comment': file_comment,
				'user': staff_user,
			})
			content = template.render(variables)

			send_an_email(staff_user.get_full_name(), staff_user.email, subject, content)

		# Send email to clients if the file is not private
		if (not theFile.private) and project.company:
			clients = User.objects.filter(companies__id=project.company.id).exclude(pk=author.id).exclude(pk=1) # excluding author and admin

			for client in clients:
				variables = Context({
					'main_url': settings.MAIN_URL,
					'author': author,
					'project': project,
					'file': theFile,
					'file_comment': file_comment,
					'user': client,
				})
				content = template.render(variables)

				send_an_email(client.get_full_name(), client.email, subject, content)

		return_data = file_comment
	elif request.method == 'PUT':# update
		requestData = simplejson.loads(request.body)

		file_comment = get_object_or_404(FileComment, pk=id)

		if not is_user_allowed_to(request.user, 'update', file_comment):
			raise Http404

		file_comment.content = requestData.get('content')

		file_comment.save()

		return_data = file_comment
	elif request.method == 'DELETE':# delete
		file_comment = get_object_or_404(FileComment, pk=id)

		if not is_user_allowed_to(request.user, 'delete', file_comment):
			raise Http404

		file_comment.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def companies_api(request, id = False):
	return_data = {}

	if request.method == 'GET':# read
		if id:
			if request.user.is_staff:
				company = get_object_or_404(Company, pk=id)
			else:
				company = get_object_or_404(Company, pk=id, users__id=request.user.id)

			return_data = company
		else:
			if request.user.is_staff:
				companies = list( Company.objects.all() )
			else:
				companies = list( Company.objects.filter(users__id=request.user.id) ) 

			return_data = companies
	elif request.method == 'POST':# create
		if not request.user.is_staff:
			raise Http404

		requestData = simplejson.loads(request.body)

		userIds = []

		for userId in requestData.get('users', None):
			userObject = get_object_or_404(User, pk=userId)
			userIds.append( userObject )

		company = Company(
			name = requestData.get('name'),
			slug = unique_slug( Company, requestData.get('name') ),
			url = requestData.get('url'),
			users = userIds,
		)

		company.save()

		return_data = company
	elif request.method == 'PUT':# update
		if not request.user.is_staff:
			raise Http404

		requestData = simplejson.loads(request.body)

		company = get_object_or_404(Company, pk=id)

		userIds = []

		for userId in requestData.get('users', None):
			userObject = get_object_or_404(User, pk=userId)
			userIds.append( userObject )

		company.name = requestData.get('name')
		company.url = requestData.get('url')
		company.users = userIds

		company.save()

		return_data = company
	elif request.method == 'DELETE':# delete
		if not request.user.is_staff:
			raise Http404

		company = get_object_or_404(Company, pk=id)

		company.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def users_api(request, id = False):
	return_data = {}

	if request.method == 'GET':# read
		if id:
			if request.user.is_staff:
				user = get_object_or_404(User, pk=id)
			elif id == request.user.id:
				user = get_object_or_404(User, pk=id)
			else:
				raise Http404

			return_data = user
		elif request.GET.get('project_id', None):
			project = get_project_if_youre_allowed(request, int(request.GET.get('project_id')))

			if project.company:
				users = list( chain( User.objects.filter(is_staff=True).exclude(pk=1), User.objects.filter(companies__id=project.company.id).exclude(pk=1) ) )# Excluding admin
			else:
				users = list( User.objects.filter(is_staff=True).exclude(pk=1) )# Excluding admin

			return_data = users
		else:
			raise Http404
			
	elif request.method == 'POST':# create
		if not request.user.is_staff:
			raise Http404

		requestData = simplejson.loads(request.body)

		user = User(
			first_name = requestData.get('first_name'),
			last_name = requestData.get('last_name'),
			username = requestData.get('username'),
			email = requestData.get('email'),
		)

		user.save()

		return_data = user
	elif request.method == 'PUT':# update
		if not request.user.is_staff:
			raise Http404

		requestData = simplejson.loads(request.body)

		user = get_object_or_404(User, pk=id)

		user.first_name = requestData.get('first_name')
		user.last_name = requestData.get('last_name')
		user.email = requestData.get('email')

		user.save()

		return_data = user
	elif request.method == 'DELETE':# delete
		if not request.user.is_staff:
			raise Http404

		user = get_object_or_404(User, pk=id)

		user.delete()

		return_data = True
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')