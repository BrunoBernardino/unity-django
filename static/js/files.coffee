$(document).ready ->
	window.unityApp.fileView = new FileView el: $('#project-files')

	# Update File button
	$(document).on 'click.unity', '.modal[data-identifier=' + Sha1.hash('files-edit') + '] .modal-footer .btn-primary', (event) ->
		event.preventDefault();
		$('div.dialog-form.files-edit form').trigger 'submit' 

		true

	# Update File
	$(document).on 'submit.unity', 'div.dialog-form.files-edit form', (event) ->
		event.preventDefault()
		window.unityApp.startLoading()

		formElement = event.target

		file = window.unityApp.fileView.fileCollection.get $(formElement).data('id')

		fileAttributes = {
			description: $(formElement).find('textarea[name="description"]').val()
		}

		file.save(
			fileAttributes
			success: (model, response) ->
				window.unityApp.fileView.render()
				window.unityApp.stopLoading()
				window.unityApp.closeAllDialogs()

				true
		)

		false

	true

# Views
FileView = Backbone.View.extend
	initialize: ->
		this.fileCollection = new window.unityApp.FileCollection()
		this.render()

	events:
		'click a.edit': 'edit'
		'click a.delete': 'delete'

	render: ->
		backboneViewObject = this

		this.fileCollection.fetch
			data:
				project_id: $('#main').data 'project'
			dataType: 'json'      
			type: 'GET'
			success: (collection, response) ->
				if response
					$(backboneViewObject.el).empty()

					fileViewTemplate = _.template $('#templates-backbone-file').html(), files: response

					$(backboneViewObject.el).append fileViewTemplate

					$('.file .actions a').tooltip()
				else
					window.unityApp.showError( window.unityApp.i18n.error.message )

	edit: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		fileId = parseInt( $(infoElement).data('id'), 10)

		dialogData = {
			modal:
				header: 'Edit File'
				identifier: 'files-edit'
			info:
				model: 'File'
				crud: 'update'
				url: window.unityApp.fileView.fileCollection.url
			file: backboneViewObject.fileCollection.get fileId
		}

		buttonData = {
			classes: 'btn-primary'
			text: 'Update File'
		}

		window.unityApp.showDialog 'files-edit', dialogData, buttonData
		
		$('input[name="due_date"]').datepicker()

	delete: (event) ->
		event.preventDefault()

		infoElement = $(event.target).closest 'a'

		$(infoElement).tooltip('hide')

		backboneViewObject = this

		bootbox.confirm 'Are you sure you want to remove this file? This action is irreversible!', (answer) ->
			if answer
				fileId = parseInt( $(infoElement).data('id'), 10)
				file = backboneViewObject.fileCollection.get fileId
				
				file.destroy
					success: ->
						backboneViewObject.render()

						true
			false

		false