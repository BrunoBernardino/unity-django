$(document).ready ->
	options = {
		onMonthChanging: (dateIn) ->
			getEventsFor dateIn
			false
	}
	
	$.jMonthCalendar.Initialize options, []

	now = new Date()

	getEventsFor $.format.date(now, 'yyyy-MM-dd')

	true

getEventsFor = (dateToFetch) ->
	window.unityApp.startLoading()

	dateToFetch = $.format.date(dateToFetch, 'yyyy-MM-dd')

	$.ajax '/ajax/calendar',
		type: 'GET'
		dataType: 'json'
		data:
			date: dateToFetch

		error: (jqXHR, textStatus, errorThrown) ->
			window.unityApp.stopLoading()
			window.unityApp.showError errorThrown
			false

		success: (response, textStatus, jqXHR) ->
			window.unityApp.stopLoading()
			
			if response.data
				$.jMonthCalendar.ReplaceEventCollection response.data

				$('.event').tooltip()
			else if response.error
				window.unityApp.showError response.msg
			else
				window.unityApp.showError window.unityApp.i18n.error.message

			true

	true