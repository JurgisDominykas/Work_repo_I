# --
# Kernel/Modules/AdminFieldTree.pm - admin frontend of general catalog management
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --

# $Id: AdminFieldTree.pm,v 1.22 2009/05/18 09:40:46 mh Exp $
# --
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminFieldTree;

use strict;
use warnings;

use Data::Dumper;

#our $ObjectManagerDisabled = 1;

our @ObjectDependencies = (
    'Kernel::System::FieldTree',
    'Kernel::System::Valid',
    'Kernel::System::Queue',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Web::Request',
    'Kernel::System::Log',
    'Kernel::Config',
);

use vars qw($VERSION);
$VERSION = qw($Revision: 1.22 $) [1];


sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}


sub Run {
    my ( $Self, %Param ) = @_;
    
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    # ------------------------------------------------------------ #
    # catalog item list
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ItemList' ) {
        my $Class = $ParamObject->GetParam( Param => "Class" ) || '';

        # check needed class
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" ) if !$Class;

        # get catalog class list
        my $ClassList       = $Kernel::OM->Get('Kernel::System::FieldTree')->ClassList();
        my $ClassOptionStrg = $LayoutObject->BuildSelection(
            Name         => 'Class',
            Data         => $ClassList,
            SelectedID   => $Class,
            PossibleNone => 1,
            Translation  => 0,
        );

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => {
                %Param,
                ClassOptionStrg => $ClassOptionStrg,
            },
        );
        $LayoutObject->Block(
            Name => 'OverviewItem',
            Data => {
                %Param,
                Class => $Class,
            },
        );

        # get availability list
        my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();

        # get catalog item list
        my $ItemIDList = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemListSorted(
            Class => $Class,
            Valid => 0,
            ParentID => -1,
        );

        # check item list
        return $LayoutObject->ErrorScreen()
            if !$ItemIDList || !@{$ItemIDList};

        my $CssClass = '';
        for my $ItemID ( @{$ItemIDList} ) {
            # set output class
            $CssClass = $CssClass eq 'searchactive' ? 'searchpassive' : 'searchactive';

            # get item data
            my $ItemData = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemGet(
                ItemID => $ItemID,
            );

            # output overview item list
            $LayoutObject->Block(
                Name => 'OverviewItemList',
                Data => {
                    %{$ItemData},
                    CssClass      => $CssClass,
                    ParentID => 	$ItemData->{ParentID},
                    Valid         => $ValidList{ $ItemData->{ValidID} },
                },
            );
        }

        # output header and navbar
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # create output string
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminFieldTree',
            Data         => \%Param,
        );

        # add footer
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # catalog item edit
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ItemEdit' ) {
        my %ItemData;
        my $log;

        # get params
        $ItemData{ItemID} = $ParamObject->GetParam( Param => "ItemID" );
        if ( $ItemData{ItemID} eq 'NEW' ) {

            # get class
            $ItemData{Class} = $ParamObject->GetParam( Param => "Class" );

            # redirect to overview
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" )
                if !$ItemData{Class};
        }
        else {

            # get item data
            my $ItemDataRef = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemGet(
                ItemID => $ItemData{ItemID},
            );

            # check item data
            return $LayoutObject->ErrorScreen()
                if !$ItemDataRef;

            %ItemData = %{$ItemDataRef};
        }

        # generate ClassOptionStrg
        my $ClassList       = $Kernel::OM->Get('Kernel::System::FieldTree')->ClassList();
        my $ClassOptionStrg = $LayoutObject->BuildSelection(
            Name         => 'Class',
            Data         => $ClassList,
            SelectedID   => $ItemData{Class},
            PossibleNone => 1,
            Translation  => 0,
        );

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => {
                %Param,
                ClassOptionStrg => $ClassOptionStrg,
            },
        );


        # generate ValidOptionStrg
        my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
        my %ValidListReverse = reverse %ValidList;
        my $ValidOptionStrg  = $LayoutObject->BuildSelection(
            Name       => 'ValidID',
            Data       => \%ValidList,
            SelectedID => $ItemData{ValidID} || $ValidListReverse{valid},
        );

        if ($ItemData{ItemID} eq 'NEW') {
        	my $TempParentId = $ParamObject->GetParam( Param => "ParentID" );
        	if ($TempParentId) {
	        	$ItemData{ParentID} = $TempParentId;
	        }
	        else { #Provide the root ID
	        	$ItemData{ParentID} = -1;
	        }
        }

        # output ItemEdit
        $LayoutObject->Block(
            Name => 'ItemEdit',
            Data => {
                %ItemData,
                ValidOptionStrg         => $ValidOptionStrg,
            },
        );

        if ( $ItemData{Class} eq 'NEW' ) {

            # output ItemEditClassAdd
            $LayoutObject->Block(
                Name => 'ItemEditClassAdd',
                Data => {
                    Class => $ItemData{Class},
                },
            );
        }
        else {

            # output ItemEditClassExist
            $LayoutObject->Block(
                Name => 'ItemEditClassExist',
                Data => {
                    Class => $ItemData{Class},
                },
            );
        }
        
        if ($ItemData{ItemID} eq 'NEW') {
        }
        else {
	        
	      # Populate child items list
	        my $ItemIDList = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemListSorted(
	            Valid => 0,
				Class => $ItemData{Class},      
				ParentID=> $ItemData{ItemID}
			);
	

	        $LayoutObject->Block(
	               Name => 'OverviewChildItems',
	                Data => {
	                    ItemID=>$ItemData{ItemID},
	                    Class =>$ItemData{Class}
	                },
	            );
			
	        my $CssClass = '';
	        for my $ChildItemID ( @{$ItemIDList} ) {
	
	            # set output class
	            $CssClass = $CssClass eq 'searchactive' ? 'searchpassive' : 'searchactive';
	
	            # get item data
	            my $ChildItemData = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemGet(
	                ItemID => $ChildItemID,
	            );
	
	            # output overview item list
	            $LayoutObject->Block(
	                Name => 'OverviewChildItemList',
	                Data => {
	                    %{$ChildItemData},
	                    CssClass      => $CssClass,
	                    Valid         => $ValidList{ $ChildItemData->{ValidID} },
	                },
	            );
	        }        
			
			
			my $SubFieldaction = $ParamObject->GetParam( Param => "SubFieldaction" );
			
			if  (defined($SubFieldaction) && $SubFieldaction eq 'FieldEdit') {

				my %FieldData;
				$FieldData{FieldID} = $ParamObject->GetParam( Param => "FieldID" );
		        if ( $FieldData{FieldID} eq 'NEW' ) {
		            # get leaf id
		            $FieldData{FieldTreeID} = $ParamObject->GetParam( Param => "ItemID" );
		
		            # redirect to overview
		            return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" )
		                if !$FieldData{FieldTreeID};
		        }
		        else {
		
		            # get item data
		            my $FieldDataRef = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldGet(
		                FieldID => $FieldData{FieldID},
		            );
		
		            # check item data
		            return $LayoutObject->ErrorScreen()
		                if !$FieldDataRef;
		
		            %FieldData = %{$FieldDataRef};
		        }
		        
		        my $checked = '';
		        if ($FieldData{Required}) {
		        	$checked = ' checked';
		        }
				my $FieldTypes = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldTypes();

		        my $FieldTypesStr  = $LayoutObject->BuildSelection(
		            Name       => 'FieldType',
		            Data       => $FieldTypes,
		            SelectedID => $FieldData{FieldType},
		        );
		        
		        
		        
		        my $ClassList       = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ClassList();
		        my $ClassOptionStrg = $LayoutObject->BuildSelection(
		            Name         => 'Template',
		            Data         => $ClassList,
		            SelectedID   => $FieldData{Template},
		            PossibleNone => 1,
		            Translation  => 0,
		        );
		        
		        my %QueueList       = $Kernel::OM->Get('Kernel::System::Queue')->QueueList();
		        my $QueueStr = $LayoutObject->BuildSelection(
		            Name         => 'Template',
		            Data         => \%QueueList,
		            SelectedID   => $FieldData{Template},
		            PossibleNone => 1,
		            Translation  => 0,
		        );
		        
		        my $Parent = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemGet(ItemID=>$FieldData{FieldTreeID});
		        my $FieldDetailsBlock = "FieldDetailsGeneral";
		        if ($Parent->{Class} eq "Templates") {
		            $FieldDetailsBlock = "FieldDetailsTemplates";
		        }
		        
                for (("FieldEdit", $FieldDetailsBlock))
                {
                    
                
		       
		        $LayoutObject->Block(
                    Name => $_,
                    Data => {
                        %FieldData,
                        ValidOptionStrg => $ValidOptionStrg,
                        Checked => $checked,
                        FieldTypesStr => $FieldTypesStr,
                        ClassOptionStrg => $ClassOptionStrg,
                        QueueStr => $QueueStr,
                    },
                );
                 
                }
			}
			
			
			{
	
				# Populate fields list
		        my $ItemIDList = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldList(
		            Valid => 0,
					FieldTreeID => $ItemData{ItemID},      
				);
				
		
	
		        $LayoutObject->Block(
		               Name => 'OverviewFields',
		               Data => {
		                    ItemID=>$ItemData{ItemID},
		               },
		            );
		        my $CssClass = '';
		        
		my @FieldList;

		for my $FieldID ( keys %{$ItemIDList} ) {
			my $Field = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldGet(
	                    FieldID => $FieldID,
			);
			push @FieldList, $Field;
		}
		
		for my $ChildItemData ( sort { $a->{Position} <=> $b->{Position} } @FieldList ) {
		
			
			my $ChildItemID = $ChildItemData->{FieldID};
		        
		            # set output class
		            $CssClass = $CssClass eq 'searchactive' ? 'searchpassive' : 'searchactive';
		
		            # get item data
		            my $ChildItemData = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldGet(
		                FieldID => $ChildItemID,
		            );
		
		            # output overview item list
		            $LayoutObject->Block(
		                Name => 'OverviewFieldList',
		                Data => {
		                    %{$ChildItemData},
		                    CssClass      => $CssClass,
		                    Valid         => $ValidList{ $ChildItemData->{ValidID} },
		                },
		            );
		        }


        $LayoutObject->Block(
	         Name => 'OverviewXML',
             Data => {
	        	 ItemID=>$ItemData{ItemID},
	     	}
	     );
				
		for my $ChildItemData ( sort { $a->{Position} <=> $b->{Position} } @FieldList ) {
		
			
			my $ChildItemID = $ChildItemData->{FieldID};
		        
		            # set output class
		            $CssClass = $CssClass eq 'searchactive' ? 'searchpassive' : 'searchactive';
		
		            # get item data
		            my $ChildItemData = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldGet(
		                FieldID => $ChildItemID,
		            );
		
		            # output overview item list
		            $LayoutObject->Block(
		                Name => 'OverviewXMLFieldList',
		                Data => {
		                    %{$ChildItemData},
		                    CssClass      => $CssClass,
		                    Valid         => $ValidList{ $ChildItemData->{ValidID} },
		                },
		            );
		        }
		    }
	    }


        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        # create output string
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminFieldTree',
            Data         => \%Param,
        );

        # add footer
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # field save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'FieldSave' ) {
        my %FieldData;

        # get params
        for my $Param (qw(FieldType FieldID Name FriendlyName Template Target 
                           Position Required Hidden ValidID Comment)) {
            $FieldData{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }
        if ( $FieldData{FieldType} eq "UserInfoFetcher" ) {
            my %FIDs;
            
            for my $Param (qw(Template_UIF_CellularAccountNo Template_UIF_StreetName Template_UIF_PlaceName
                            Template_UIF_AreaName Template_UIF_CountryName)) {
                $FIDs{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
            }
            $FieldData{Template} = "$FIDs{Template_UIF_CellularAccountNo};$FIDs{Template_UIF_StreetName};$FIDs{Template_UIF_PlaceName};$FIDs{Template_UIF_AreaName};$FIDs{Template_UIF_CountryName}";
        }
        $FieldData{FieldTreeID} = $ParamObject->GetParam( Param => 'ItemID' );
        my $ItemID = $FieldData{FieldTreeID};

        # check class
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" )
            if !$FieldData{FieldTreeID};

        # save to database
        my $Success;
        my $FieldID;
        if ( $FieldData{FieldID} eq 'NEW' ) {
            $Success = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldAdd(
                %FieldData,
                UserID => $Self->{UserID},
            );
            $FieldID = $Success;
        }
        else {
            $Success = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldUpdate(
                %FieldData,
                UserID => $Self->{UserID},
            );
            $FieldID = $FieldData{FieldID};
        }

        return $LayoutObject->ErrorScreen() if !$Success;

        # redirect to overview class list,except we are adding first level item
        return $LayoutObject->Redirect(
            OP => "Action=$Self->{Action}&Subaction=ItemEdit&ItemID=$ItemID"
        );            
    }

    # ------------------------------------------------------------ #
    # catalog item save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ItemSave' ) {
        my %ItemData;

        # get params
        for my $Param (qw(Class ItemID Name FriendlyName ParentID ValidID CssClass Comment Position)) {
            $ItemData{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # check class
        return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" )
            if !$ItemData{Class} || $ItemData{Class} eq 'NEW';

        # save to database
        my $Success;
        my $ItemID;
        if ( $ItemData{ItemID} eq 'NEW' ) {
            $Success = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemAdd(
                %ItemData,
                UserID => $Self->{UserID},
            );
            $ItemID = $Success;
        }
        else {
            $Success = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemUpdate(
                %ItemData,
                UserID => $Self->{UserID},
            );
            $ItemID = $ItemData{ItemID};
        }

        return $LayoutObject->ErrorScreen() if !$Success;

        if ($ItemData{ParentID} != -1) {
            return $LayoutObject->Redirect(
                OP => "Action=$Self->{Action}&Subaction=ItemEdit&ItemID=$ItemData{ParentID}"
            );
        }
        else {
            return $LayoutObject->Redirect(
                OP => "Action=$Self->{Action}"
            );            
        }

        # redirect to overview class list
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {

        # get catalog class list
        my $ClassList       = $Kernel::OM->Get('Kernel::System::FieldTree')->ClassList();
        my $ClassOptionStrg = $LayoutObject->BuildSelection(
            Name         => 'Class',
            Data         => $ClassList,
            PossibleNone => 1,
            Translation  => 0,
        );

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => {
                %Param,
                ClassOptionStrg => $ClassOptionStrg,
            },
        );
        $LayoutObject->Block(
            Name => 'OverviewClass',
            Data => {
                %Param,
            },
        );

        my $CssClass = '';
        for my $Class ( @{$ClassList} ) {

            # set output class
            $CssClass = $CssClass eq 'searchactive' ? 'searchpassive' : 'searchactive';

            # output overview class list
            $LayoutObject->Block(
                Name => 'OverviewClassList',
                Data => {
                    Class    => $Class,
                    CssClass => $CssClass,
                },
            );
        }

        # output header and navbar
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # create output string
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminFieldTree',
            Data         => \%Param,
        );

        # add footer
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

1;
