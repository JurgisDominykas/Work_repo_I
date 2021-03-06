Core.App.Ready(function () {
	
	
	/**
	 * Custom validation filters are being created here.
	 */

	$.validator.addMethod("Validate_Phone", function (Value, Element) {
		phoneTest = /^([0-9\(\)\/\+ \-]*)$/;
		
		return phoneTest.test(Value);
	});

	$.validator.addMethod("Validate_Money", function (Value, Element) {
		moneyTest = /^\$?[0-9]+(,[0-9]{3})*(\.[0-9]{2})?$/;
		
		return moneyTest.test(Value);
	});
	
	
	
	/**
	 * Closes every opened fieldtree branch except the one given(and it's parent branches).
	 */
	
	function CollapseAll(except){
		
		/**
		 *  Finds branch's and it's ancestors'(if there are any) identifiers.
		 */
		
		if(except.hasClass('Level1Opener'))
		{
			var firstlvl = 'FieldTreeHolder-' + except.attr('rel');
			var secondlvl = null;
		}
		else
		{
			var firstlvl = except.parent().parent().attr('id');
			var secondlvl = 'FieldTreeHolder-' + except.attr('rel');
		}
		
		
		/**
		 * Closes first level branches
		 */
			
		$('.FieldTree > .FieldTreeHolder').each(function(){
			if($(this).attr('id') != firstlvl)
			{
				$(this).slideUp(500);
				$(this).parent().find('a[rel=\'' + $(this).attr('id').substring(16) + '\'] span').html('&#9656;');
			}
		});
		

		/**
		 * Closes second level branches
		 */
		
		$('.FieldTree > .FieldTreeHolder > .FieldTreeHolder-Level2').each(function(){
			if($(this).attr('id') != secondlvl)
				$(this).slideUp(500);
		});
		
	}
	
    $('a.Level1Opener').click(function(e) {
		
    	/**
    	 * If Subject is not set, fills it in with the name of selected fieldtree branch.
    	 */
    	if($("form input[name=Subject]").val() == '')
    		$("form input[name=Subject]").val($(this).text().substring(3));
    	
    	/**
    	 * Finds a fieldtree containing this object.
    	 */
    	that = $(this);
    	
    	Scope = null;
    	
    	$(".FieldTreeForm").each(function(){
    		if($(this).find(that).length == 1)
    			Scope = $(this);
    	});
    	if(Scope == null)
    		return;
    	
    	var DynamicFieldName = Scope.find(".FieldTreeName").attr('name');
    	var IsReadOnly = Scope.find("input[name=" + DynamicFieldName + "_ReadOnly]").val();
    	Scope.find("input[name=" + DynamicFieldName + "_FieldTreeID]").val($(this).attr('rel'));
    	
    	var holder = Scope.find('#FieldTreeHolder-'+$(this).attr('rel'));
	    
	    if (holder.css('display') == 'none')
	    {
			if(Core.Config.Get('Action').substring(0, 5) == 'Agent')
				var Action = 'AgentFieldTree'
			else
				var Action = 'CustomerFieldTree';
			
	    	var FieldTreeValueSetId = Scope.find('input[name=' + DynamicFieldName + ']').val();
	    	
	    	holder.find(".ForDynamicLoad div.DynamiclyLoadedContent").load(
	    		Core.Config.Get('Baselink'),
	    		{
	    			'Action': Action,
	    			'Subaction': 'AjaxFields',
	    			'ItemID': $(this).attr('rel'),
	    			'DynamicFieldName': DynamicFieldName,
	    			'ValueSetID': FieldTreeValueSetId,
	    			'Disabled': IsReadOnly,
	    			'DoNotShowWarnings': 1
	    		}, 
	    		function() {
		   			holder.slideDown(500);
		   			
		    		CollapseAll(that);
		    		
		    		/**
		    		 * Checks whether opened branch has any input fields.
		    		 */
		    		var somethingMeaningful = holder.find(".ForDynamicLoad div.DynamiclyLoadedContent input[name=NoFieldsLoaded]").length == 0;
	    			Scope.find("input[name=" + DynamicFieldName + "_Selected]").val(somethingMeaningful ? 1 : "");
	    			
	    			if(somethingMeaningful)
	    				Scope.removeClass('ErrorNotSelected');
	    			
	    			/**
	    			 * After fieldtree inputs have been loaded we must re-init validator engine.
	    			 */
	    			Core.Form.Validate.Init();
	    	});
	   	}
    });
    
    $('a.Level2Opener').click(function(e) {
		
    	/**
    	 * If Subject is not set, fills it in with the name of selected fieldtree branch.
    	 */
    	if($("form input[name=Subject]").val() == '')
    		$("form input[name=Subject]").val($(this).text().substring(3));
    	
    	/**
    	 * Finds a fieldtree containing this object.
    	 */
    	that = $(this);
    	
    	Scope = null;
    	
    	$(".FieldTreeForm").each(function(){
    		if($(this).find(that).length == 1)
    			Scope = $(this);
    	});
    	if(Scope == null)
    		return;
		
    	var DynamicFieldName = Scope.find(".FieldTreeName").attr('name');
    	var IsReadOnly = Scope.find("input[name=" + DynamicFieldName + "_ReadOnly]").val();
    	Scope.find("input[name=" + DynamicFieldName + "_FieldTreeID]").val($(this).attr('rel'));
    	
    	var holder = Scope.find('#FieldTreeHolder-'+$(this).attr('rel'));
	    
	    if (holder.css('display') == 'none')
	    {
			if(Core.Config.Get('Action').substring(0, 5) == 'Agent')
				var Action = 'AgentFieldTree'
			else
				var Action = 'CustomerFieldTree';
			
	    	var FieldTreeValueSetId = Scope.find('input[name=' + DynamicFieldName + ']').val();
	    	
	    	holder.hide().load(
	    		Core.Config.Get('Baselink'),
	    		{
	    			'Action': Action,
	    			'Subaction': 'AjaxFields',
	    			'ItemID': $(this).attr('rel'),
	    			'DynamicFieldName': DynamicFieldName,
	    			'ValueSetID': FieldTreeValueSetId,
	    			'Disabled': IsReadOnly
	    		}, 
	    		function() {
		   			holder.slideDown(500);
		   			
		    		CollapseAll(that);
		    		
		    		/**
		    		 * Checks whether opened branch has any input fields.
		    		 */
		    		var somethingMeaningful = holder.find("input[name=NoFieldsLoaded]").length == 0;
	    			Scope.find("input[name=" + DynamicFieldName + "_Selected]").val(somethingMeaningful ? 1 : "");
	    			
	    			if(somethingMeaningful)
	    				Scope.removeClass('ErrorNotSelected');
	    			
	    			
	    			/**
	    			 * After fieldtree inputs have been loaded we must re-init validator engine.
	    			 */
	    			Core.Form.Validate.Init();
	    	});
	   	}
    });
     
});

/**
 * Finally, after all the config is set, we can dynamicly load fieldtree content for preview.
 */

Core.App.Finally(function () {

	$(".FieldTreePreview").each(function(){
			
		var DynamicFieldName = $(this).find(".FieldTreeName").attr('name');
		
		if(Core.Config.Get('Action').substring(0, 5) == 'Agent')
			var Action = 'AgentFieldTree'
		else
			var Action = 'CustomerFieldTree';
		
		that = $(this);
		
		$(this).find(".FieldTreeHolder-Level2").load(
			Core.Config.Get('Baselink'),
			{
				'Action': Action,
				'Subaction': 'AjaxFields',
				'ItemID': $(this).find("input[name=" + DynamicFieldName + "_FieldTreeID]").val(),
				'DynamicFieldName': DynamicFieldName,
				'ValueSetID': $(this).find("input[name=" + DynamicFieldName + "]").val(),
				'Disabled': $(this).find("input[name=" + DynamicFieldName + "_ReadOnly]").val()
			},
			function(){
				that.show();
			}
		);
		
	});
});