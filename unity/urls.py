from django.conf.urls import patterns, include, url

from django.contrib import admin
admin.autodiscover()

urlpatterns = patterns('',
	# Examples:
	# url(r'^$', 'unity.views.home', name='home'),
	# url(r'^unity/', include('unity.foo.urls')),

	url(r'^admin/', include(admin.site.urls)),

	url(r'^projects/$', 'projects.views.projects', name = 'projects'),
	url(r'^projects/(?P<project_slug>[\w-]+)/$', 'projects.views.project'),

	url(r'^projects/(?P<project_slug>[\w-]+)/milestones/$', 'projects.views.milestones', name = 'project-milestones'),
	url(r'^projects/(?P<project_slug>[\w-]+)/milestones/(?P<milestone_slug>[\w-]+)/$', 'projects.views.milestone'),

	url(r'^projects/(?P<project_slug>[\w-]+)/discussions/$', 'projects.views.discussions', name = 'project-discussions'),
	url(r'^projects/(?P<project_slug>[\w-]+)/discussions/(?P<discussion_slug>[\w-]+)/$', 'projects.views.discussion'),

	url(r'^projects/(?P<project_slug>[\w-]+)/lists/$', 'projects.views.lists', name = 'project-lists'),
	url(r'^projects/(?P<project_slug>[\w-]+)/lists/(?P<list_slug>[\w-]+)/$', 'projects.views.list'),
	url(r'^projects/(?P<project_slug>[\w-]+)/lists/(?P<list_slug>[\w-]+)/(?P<task_slug>[\w-]+)/$', 'projects.views.task'),

	url(r'^projects/(?P<project_slug>[\w-]+)/files/$', 'projects.views.files', name = 'project-files'),
	url(r'^projects/(?P<project_slug>[\w-]+)/files/(?P<file_slug>[\w-]+)/$', 'projects.views.file'),

	url(r'^users/(?P<username>[\w-]+)/$', 'projects.views.user', name = 'user'),
	url(r'^profile/$', 'projects.views.profile', name = 'profile'),

	url(r'^companies/$', 'projects.views.companies', name = 'companies'),
	url(r'^companies/(?P<company_slug>[\w-]+)/$', 'projects.views.company'),

	url(r'^calendar/$', 'projects.views.calendar', name = 'calendar'),
	url(r'^tasks/$', 'projects.views.tasks', name = 'tasks'),

	url(r'^password-reset/$', 'django.contrib.auth.views.password_reset', name = 'password-reset'),
    url(r'^password-reset/done/$', 'django.contrib.auth.views.password_reset_done'),
    url(r'^reset/(?P<uidb36>[0-9A-Za-z]{1,13})-(?P<token>[0-9A-Za-z]{1,13}-[0-9A-Za-z]{1,20})/$', 'django.contrib.auth.views.password_reset_confirm'),
    url(r'^reset/done/$', 'django.contrib.auth.views.password_reset_complete'),
	url(r'^login/$', 'django.contrib.auth.views.login'),
	url(r'^logout/$', 'django.contrib.auth.views.logout', {'next_page': '/login/'}),
	url(r'^$', 'projects.views.dashboard'),

	# AJAX
	url(r'^ajax/calendar$', 'projects.views.ajax_calendar', name = 'ajax-calendar'),
	url(r'^ajax/files$', 'projects.views.ajax_files', name = 'ajax-files'),
	url(r'^ajax/profile$', 'projects.views.ajax_profile', name = 'ajax-profile'),

	# RESTful API
	url(r'^api/projects$', 'projects.views.projects_api', name = 'api-projects'),
	url(r'^api/projects/(?P<id>\d+)$', 'projects.views.projects_api', name = 'api-project'),
	url(r'^api/milestones$', 'projects.views.milestones_api', name = 'api-milestones'),
	url(r'^api/milestones/(?P<id>\d+)$', 'projects.views.milestones_api', name = 'api-milestone'),
	url(r'^api/discussions$', 'projects.views.discussions_api', name = 'api-discussions'),
	url(r'^api/discussions/(?P<id>\d+)$', 'projects.views.discussions_api', name = 'api-discussion'),
	url(r'^api/discussion_comments$', 'projects.views.discussion_comments_api', name = 'api-discussion-comments'),
	url(r'^api/discussion_comments/(?P<id>\d+)$', 'projects.views.discussion_comments_api', name = 'api-discussion-comment'),
	url(r'^api/lists$', 'projects.views.lists_api', name = 'api-lists'),
	url(r'^api/lists/(?P<id>\d+)$', 'projects.views.lists_api', name = 'api-list'),
	url(r'^api/tasks$', 'projects.views.tasks_api', name = 'api-tasks'),
	url(r'^api/tasks/(?P<id>\d+)$', 'projects.views.tasks_api', name = 'api-task'),
	url(r'^api/task_comments$', 'projects.views.task_comments_api', name = 'api-task-comments'),
	url(r'^api/task_comments/(?P<id>\d+)$', 'projects.views.task_comments_api', name = 'api-task-comment'),
	url(r'^api/files$', 'projects.views.files_api', name = 'api-files'),
	url(r'^api/files/(?P<id>\d+)$', 'projects.views.files_api', name = 'api-file'),
	url(r'^api/file_comments$', 'projects.views.file_comments_api', name = 'api-file-comments'),
	url(r'^api/file_comments/(?P<id>\d+)$', 'projects.views.file_comments_api', name = 'api-file-comment'),
	url(r'^api/companies$', 'projects.views.companies_api', name = 'api-companies'),
	url(r'^api/companies/(?P<id>\d+)$', 'projects.views.companies_api', name = 'api-company'),
	url(r'^api/users$', 'projects.views.users_api', name = 'api-users'),
	url(r'^api/users/(?P<id>\d+)$', 'projects.views.users_api', name = 'api-user'),
)