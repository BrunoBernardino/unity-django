# Create your ajax views here.
from django.views.generic.simple import direct_to_template
from django.http import HttpResponse, Http404
from django.shortcuts import render_to_response, get_object_or_404
from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.utils import simplejson, timezone
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.contrib import messages

import datetime
import calendar

from projects.models import *

from projects.views import get_project_if_youre_allowed, json_custom_encoding, get_random_hash, unique_slug

# AJAX views
@login_required()
def ajax_calendar(request):
	return_data = { 'error': True, 'msg': '', 'data': None }

	if not request.is_ajax():
		raise Http404

	if request.GET.get('date', None):

		events = []
		uniqueEventIDs = 0

		dateObject = datetime.datetime.utcnow().replace(tzinfo=timezone.utc).strptime( request.GET.get('date'), '%Y-%m-%d' ) 

		if dateObject.month == 1:
			startDateYear = dateObject.year - 1
			startDateMonth = 12
			endDateYear = dateObject.year
			endDateMonth = dateObject.month + 1
			endDateDay = calendar.monthrange(endDateYear, endDateMonth)[1]
		elif dateObject.month == 12:
			startDateYear = dateObject.year
			startDateMonth = dateObject.month - 1
			endDateYear = dateObject.year + 1
			endDateMonth = 1
			endDateDay = calendar.monthrange(endDateYear, endDateMonth)[1]
		else:
			startDateYear = dateObject.year
			startDateMonth = dateObject.month - 1
			endDateYear = dateObject.year
			endDateMonth = dateObject.month + 1
			endDateDay = calendar.monthrange(endDateYear, endDateMonth)[1]

		startDate = datetime.datetime(year=startDateYear, month=startDateMonth, day=1, tzinfo=timezone.utc)
		endDate = datetime.datetime(year=endDateYear, month=endDateMonth, day=endDateDay, tzinfo=timezone.utc)

		# Get All Projects, to Get All Lists, to Get All Tasks with due date
		if request.user.is_staff:
			projects = list( Project.objects.filter(archived=False).order_by('-date') )
		else:
			projects = list( Project.objects.filter(archived=False, company__users__id=request.user.id).order_by('-date') ) 

		for project in projects:
			theMilestones = project.milestones.filter(completed=False, due_date__gte=startDate, due_date__lte=endDate).order_by('-due_date')
			theLists = project.lists.filter(completed=False).order_by('-date')

			# iterate through milestones to parse and add them to the events list
			for milestone in theMilestones:
				uniqueEventIDs += 1;
				parsedMilestone = {
					'id': uniqueEventIDs,
					'eDate': milestone.due_date,
					'name': milestone.name,
					'title': ("%s: %s" % ( project.name, milestone.name )),
					'url': milestone.get_absolute_url(),
					'cssClass': 'milestone',
				}
				events.append(parsedMilestone)

			for theList in theLists:
				theTasks = theList.tasks.filter(completed=False, due_date__isnull=False, due_date__gte=startDate, due_date__lte=endDate).order_by('-due_date', 'priority')
				
				# iterate through tasks to parse and add them to the events list
				for task in theTasks:
					uniqueEventIDs += 1;
					parsedTask = {
						'id': uniqueEventIDs,
						'eDate': task.due_date,
						'name': task.title,
						'title': ("%s: %s" % ( project.name, task.title )),
						'url': task.get_absolute_url(),
						'cssClass': 'task',
					}
					events.append(parsedTask)

		return_data.update(data = events)
	else:
		raise Http404

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def ajax_files(request):
	return_data = { 'error': True, 'msg': '', 'data': None }

	if request.method != 'POST':
		raise Http404

	project = get_project_if_youre_allowed(request, int(request.GET.get('project', 0)))

	if not request.FILES.getlist('files', None):
		raise Http404

	files = []

	for uploadedFile in request.FILES.getlist('files'):

		author = get_object_or_404(User, pk=request.user.id)

		newFileName = str(author.id) + '-' + get_random_hash(10)

#		filePath = default_storage.save('file/' + newFileName + '.' + uploadedFile.extension(), ContentFile( uploadedFile.read() ))
#		finalFilePath = os.path.join(settings.MEDIA_ROOT, filePath)
		finalFilePath = uploadedFile

		privateSetting = False

		if request.GET.get('object') == 'd':
			originalObject = get_object_or_404(Discussion, pk=request.GET.get('id'))
			privateSetting = originalObject.private

		elif request.GET.get('object') == 'dc':
			originalObject = get_object_or_404(DiscussionComment, pk=request.GET.get('id'))
			privateSetting = originalObject.discussion.private

		elif request.GET.get('object') == 't':
			originalObject = get_object_or_404(Task, pk=request.GET.get('id'))
			privateSetting = originalObject.list.private

		elif request.GET.get('object') == 'tc':
			originalObject = get_object_or_404(TaskComment, pk=request.GET.get('id'))
			privateSetting = originalObject.task.list.private

		elif request.GET.get('object') == 'fc':
			originalObject = get_object_or_404(FileComment, pk=request.GET.get('id'))
			privateSetting = originalObject.private

		theFile = File(
			project = project,
			name = newFileName,
			slug = unique_slug( File, newFileName ),
			file = finalFilePath,
			author = author,
			original_object = request.GET.get('object'),
			original_object_id = request.GET.get('id'),
			description = '',
			private = privateSetting
		)

		theFile.save()

		# We don't need the whole object to be returned here
		theFileToReturn = {
			'id': theFile.id,
			'filename': theFile.file.url,
			'name': theFile.name,
		}

		files.append(theFileToReturn)

	return_data.update(data = files)
	return_data.update(error = False)

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')

@login_required()
def ajax_profile(request):
	return_data = { 'error': True, 'msg': '', 'data': None }

	if request.method != 'POST':
		raise Http404

	user = get_object_or_404(User, pk=request.user.id)

	userProfile = get_user_profile(user)

	# Check if we're updating data or saving the avatar
	if request.FILES.get('avatar', None):
		userProfile.original_avatar = request.FILES.get('avatar')
	else:
		# Validate Current Password
		if not user.check_password(request.POST.get('current_password', None)):

			return_data.update(msg = 'Current password invalid!')

			json = simplejson.dumps(return_data)

			return HttpResponse(json, mimetype='application/json')

		user.first_name = request.POST.get('first_name', None)
		user.last_name = request.POST.get('last_name', None)
		user.email = request.POST.get('email', None)
		userProfile.url = request.POST.get('url', None)
		userProfile.phone = request.POST.get('phone', None)

		if request.POST.get('remove_avatar', False) == 'true':
			userProfile.original_avatar = None

		# Set New Password
		if request.POST.get('new_password', None):
			user.set_password(request.POST.get('new_password'))

		messages.success(request, 'Profile details updated.')

	user.save()
	userProfile.save()

	return_data.update(data = True)
	return_data.update(error = False)

	json = simplejson.dumps(return_data, default=json_custom_encoding)

	return HttpResponse(json, mimetype='application/json')