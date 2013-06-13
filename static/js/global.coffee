$(document).ready ->
	$.ajaxSetup
		crossDomain: false
		beforeSend: (xhr, settings) ->
			csrftoken = $.cookie 'csrftoken'

			if /^(GET|HEAD|OPTIONS|TRACE)$/.test(settings.type) == false
				xhr.setRequestHeader("X-CSRFToken", csrftoken)

	$('.spin-loading').spin()

	$(document).on 'click.unity', 'footer.footer .pull-right a', (event) ->
		event.preventDefault()

		$('body').animate scrollTop: 0, 'fast'

		true
	
	true

# "Global" Manager App variable
window.unityApp = {}

window.unityApp.i18n = {
	error:
		message: 'Oops! Something wrong happened here! Please refresh and try again.'
}

window.unityApp.startLoading = () ->
	$('#main-loading').stop().fadeIn 'fast'
	true

window.unityApp.stopLoading = () ->
	$('#main-loading').stop().fadeOut 'fast'
	true

window.unityApp.showDialog = (dialog, data, buttonData) ->
	if $('#templates-dialog-' + dialog).length == 0
		false

	contentHTML = _.template $('#templates-dialog-' + dialog).html(), data

	modal =
		DOMId: Sha1.hash(Math.random().toString())
		identifier: Sha1.hash(data.modal.identifier)
		header: data.modal.header
		body: contentHTML
		buttons: ''

	if buttonData
		if $.isArray buttonData
			for buttonSingleData in buttonData
				modal.buttons += _.template $('#templates-base-dialog-button').html(), buttonSingleData
		else
			modal.buttons = _.template $('#templates-base-dialog-button').html(), buttonData

	baseHTML = _.template $('#templates-base-dialog').html(), modal: modal

	$previousModal = $('.modal').filter -> 
		$(this).data('identifier') == modal.identifier

	if $previousModal
		$previousModal.remove()

	$('body').append baseHTML

	$('#dialog-' + modal.DOMId).modal { backdrop: 'static' }

	$('#dialog-' + modal.DOMId).on 'shown', () ->
		$('#dialog-' + modal.DOMId + ' textarea').elastic()

		$('#dialog-' + modal.DOMId + ' select').chosen()

		$('#dialog-' + modal.DOMId).draggable()

		true

	modal.DOMId

window.unityApp.closeAllDialogs = ->
	$('.modal').modal('hide')

window.unityApp.showError = (message) ->	
	contentHTML = _.template $('#templates-global-error').html(), message: message

	$('#main-alert-zone .main-alert-zone-container').append contentHTML

	$('#main-alert-zone').fadeIn 'fast'

	$('#main-alert-zone .alert').alert()

	$('#main-alert-zone .alert').off 'closed'
	$('#main-alert-zone .alert').on 'closed', () ->
		$(this).remove()

		if !$('#main-alert-zone .alert').length
			$('#main-alert-zone').fadeOut 'fast'

		false

	false

window.unityApp.showMessage = (message) ->
	contentHTML = _.template $('#templates-global-info').html(), message: message

	$('#main-alert-zone .main-alert-zone-container').append contentHTML

	$('#main-alert-zone').fadeIn 'fast'

	$('#main-alert-zone .alert').alert()

	$('#main-alert-zone .alert').off 'closed'
	$('#main-alert-zone .alert').on 'closed', () ->
		$(this).remove()

		if !$('#main-alert-zone .alert').length
			$('#main-alert-zone').fadeOut 'fast'

		false

	false

# Models & Collections
## Project
window.unityApp.Project = Backbone.Model.extend
	urlRoot: '/api/projects'
	defaults: ->
		return {
			id: null
			name: ""
			slug: ""
			description: ""
			date: ""
			archived: false
			company: {}
		}

	validate: (attrs) ->
		if !attrs.name
			return 'The project needs a name!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.ProjectCollection = Backbone.Collection.extend
	model: window.unityApp.Project
	url: '/api/projects'

## Milestone
window.unityApp.Milestone = Backbone.Model.extend
	urlRoot: '/api/milestones'
	defaults: ->
		return {
			id: null
			project: {}
			name: ""
			slug: ""
			date: ""
			due_date: ""
			description: ""
			completed: false
			completed_date: null
		}

	validate: (attrs) ->
		if !attrs.project || !attrs.project.id
			return 'Milestones need to be associated to a project!'

		if !attrs.name
			return 'The milestone needs a name!'

		if !attrs.due_date
			return 'The milestone needs a Due Date!'

		if !attrs.due_date.match(/^(\d{4,4})-(\d{2,2})-(\d{2,2}).*$/)
			return 'The milestone needs a valid Due Date!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.MilestoneCollection = Backbone.Collection.extend
	model: window.unityApp.Milestone
	url: '/api/milestones'

## Discussion
window.unityApp.Discussion = Backbone.Model.extend
	urlRoot: '/api/discussions'
	defaults: ->
		return {
			id: null
			project: {}
			title: ""
			slug: ""
			date: ""
			content: ""
			author: {}
			private: false
			completed: false
			completed_date: null
			files: []
		}

	validate: (attrs) ->
		if !attrs.title
			return 'The discussion needs a title!'

		if !attrs.content
			return 'The discussion needs a message!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.DiscussionCollection = Backbone.Collection.extend
	model: window.unityApp.Discussion
	url: '/api/discussions'

## DiscussionComment
window.unityApp.DiscussionComment = Backbone.Model.extend
	urlRoot: '/api/discussion_comments'
	defaults: ->
		return {
			id: null
			discussion: {}
			date: ""
			content: ""
			author: {}
			files: []
		}

	validate: (attrs) ->
		if !attrs.content
			return 'The comment needs a message!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.DiscussionCommentCollection = Backbone.Collection.extend
	model: window.unityApp.DiscussionComment
	url: '/api/discussion_comments'

## List
window.unityApp.List = Backbone.Model.extend
	urlRoot: '/api/lists'
	defaults: ->
		return {
			id: null
			project: {}
			name: ""
			slug: ""
			milestone: {}
			date: null
			description: ""
			author: {}
			private: false
			tasks: {}
			tasks_incomplete: {}
			tasks_complete: {}
			completed: false
		}

	validate: (attrs) ->
		if !attrs.project || !attrs.project.id
			return 'Lists need to be associated to a project!'

		if !attrs.name
			return 'The list needs a name!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.ListCollection = Backbone.Collection.extend
	model: window.unityApp.List
	url: '/api/lists'

## Task
window.unityApp.Task = Backbone.Model.extend
	urlRoot: '/api/tasks'
	defaults: ->
		return {
			id: null
			title: ""
			slug: ""
			list: {}
			description: ""
			date: null
			due_date: null
			priority: 99999
			author: {}
			responsible: {}
			completed: false
			comments: {}
			files: []
		}

	validate: (attrs) ->
		if !attrs.title
			return 'The task needs a title!'

		if !attrs.list || !attrs.list.id
			return 'Tasks need to be associated to a list!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.TaskCollection = Backbone.Collection.extend
	model: window.unityApp.Task
	url: '/api/tasks'

## TaskComment
window.unityApp.TaskComment = Backbone.Model.extend
	urlRoot: '/api/task_comments'
	defaults: ->
		return {
			id: null
			task: {}
			date: ""
			content: ""
			author: {}
			files: []
		}

	validate: (attrs) ->
		if !attrs.content
			return 'The comments needs a message!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.TaskCommentCollection = Backbone.Collection.extend
	model: window.unityApp.TaskComment
	url: '/api/task_comments'

## File
window.unityApp.File = Backbone.Model.extend
	urlRoot: '/api/files'
	defaults: ->
		return {
			id: null
			project: {}
			name: ""
			slug: ""
			file: ""
			date: null
			author: {}
			original_object: "" # options: (d, dc, t, tc, fc — Discussion, DiscussionComment, Task, TaskComment, FileComment)
			original_object_id: null
			description: ""
			private: false
		}

	validate: (attrs) ->
		if !attrs.name
			return 'The file needs a name!'

		if !attrs.file
			return 'The file needs a file!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.FileCollection = Backbone.Collection.extend
	model: window.unityApp.File
	url: '/api/files'

## FileComment
window.unityApp.FileComment = Backbone.Model.extend
	urlRoot: '/api/file_comments'
	defaults: ->
		return {
			id: null
			file: {}
			date: ""
			content: ""
			author: {}
			files: []
		}

	validate: (attrs) ->
		if !attrs.content
			return 'The comments needs a message!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.FileCommentCollection = Backbone.Collection.extend
	model: window.unityApp.FileComment
	url: '/api/file_comments'

## Company
window.unityApp.Company = Backbone.Model.extend
	urlRoot: '/api/companies'
	defaults: ->
		return {
			id: null
			name: ""
			slug: ""
			url: ""
			users: []
		}

	validate: (attrs) ->
		if !attrs.name
			return 'The company needs a name!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.CompanyCollection = Backbone.Collection.extend
	model: window.unityApp.Company
	url: '/api/companies'

## User
window.unityApp.User = Backbone.Model.extend
	urlRoot: '/api/users'
	defaults: ->
		return {
			id: null
			first_name: ""
			last_name: ""
			username: ""
			email: ""
			company: {}
		}

	validate: (attrs) ->
		if !attrs.first_name
			return 'The user needs a first name!'

		if !attrs.username
			return 'The user needs a username!'

		if !attrs.email
			return 'The user needs an email!'

	initialize: ->
		this.on 'error', (model, error) ->
			window.unityApp.stopLoading()

			if $.type(error) == 'string'
				window.unityApp.showError( error )
			else
				window.unityApp.showError( window.unityApp.i18n.error.message )

			false

window.unityApp.UserCollection = Backbone.Collection.extend
	model: window.unityApp.User
	url: '/api/users'