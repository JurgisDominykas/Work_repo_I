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

use Kernel::System::FieldTree;
use Kernel::System::Valid;
use Kernel::System::Queue;
use Data::Dumper;


use vars qw($VERSION);
$VERSION = qw($Revision: 1.22 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(ConfigObject ParamObject LogObject LayoutObject)) {
        if ( !$Self->{$Object} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Object!" );
        }
    }
    $Self->{FieldTreeObject}	= Kernel::System::FieldTree->new(%Param);
    $Self->{GeneralCatalogObject}	= Kernel::System::GeneralCatalog->new(%Param);
    $Self->{ValidObject} 		= Kernel::System::Valid->new(%Param);
    $Self->{QueueObject} 		= Kernel::System::Queue->new(%Param);

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
    
    # ------------------------------------------------------------ #
    # catalog item list
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ItemList' ) {
        my $Class = $Self->{ParamObject}->GetParam( Param => "Class" ) || '';

        # check needed class
        return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" ) if !$Class;

        # get catalog class list
        my $ClassList       = $Self->{FieldTreeObject}->ClassList();
        my $ClassOptionStrg = $Self->{LayoutObject}->BuildSelection(
            Name         => 'Class',
            Data         => $ClassList,
            SelectedID   => $Class,
            PossibleNone => 1,
            Translation  => 0,
        );

        # output overview
        $Self->{LayoutObject}->Block(
            Name => 'Overview',
            Data => {
                %Param,
                ClassOptionStrg => $ClassOptionStrg,
            },
        );
        $Self->{LayoutObject}->Block(
            Name => 'OverviewItem',
            Data => {
                %Param,
                Class => $Class,
            },
        );

        # get availability list
        my %ValidList = $Self->{ValidObject}->ValidList();

        # get catalog item list
        my $ItemIDList = $Self->{FieldTreeObject}->ItemListSorted(
            Class => $Class,
            Valid => 0,
            ParentID => -1,
        );

        # check item list
        return $Self->{LayoutObject}->ErrorScreen()
            if !$ItemIDList || !@{$ItemIDList};

        my $CssClass = '';
        for my $ItemID ( @{$ItemIDList} ) {
            # set output class
            $CssClass = $CssClass eq 'searchactive' ? 'searchpassive' : 'searchactive';

            # get item data
            my $ItemData = $Self->{FieldTreeObject}->ItemGet(
                ItemID => $ItemID,
            );

            # output overview item list
            $Self->{LayoutObject}->Block(
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
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();

        # create output string
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminFieldTree',
            Data         => \%Param,
        );

        # add footer
        $Output .= $Self->{LayoutObject}->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # catalog item edit
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ItemEdit' ) {
        my %ItemData;
        my $log;

        # get params
        $ItemData{ItemID} = $Self->{ParamObject}->GetParam( Param => "ItemID" );
        if ( $ItemData{ItemID} eq 'NEW' ) {

            # get class
            $ItemData{Class} = $Self->{ParamObject}->GetParam( Param => "Class" );

            # redirect to overview
            return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" )
                if !$ItemData{Class};
        }
        else {

            # get item data
            my $ItemDataRef = $Self->{FieldTreeObject}->ItemGet(
                ItemID => $ItemData{ItemID},
            );

            # check item data
            return $Self->{LayoutObject}->ErrorScreen()
                if !$ItemDataRef;

            %ItemData = %{$ItemDataRef};
        }

        # generate ClassOptionStrg
        my $ClassList       = $Self->{FieldTreeObject}->ClassList();
        my $ClassOptionStrg = $Self->{LayoutObject}->BuildSelection(
            Name         => 'Class',
            Data         => $ClassList,
            SelectedID   => $ItemData{Class},
            PossibleNone => 1,
            Translation  => 0,
        );

        # output overview
        $Self->{LayoutObject}->Block(
            Name => 'Overview',
            Data => {
                %Param,
                ClassOptionStrg => $ClassOptionStrg,
            },
        );


        # generate ValidOptionStrg
        my %ValidList        = $Self->{ValidObject}->ValidList();
        my %ValidListReverse = reverse %ValidList;
        my $ValidOptionStrg  = $Self->{LayoutObject}->BuildSelection(
            Name       => 'ValidID',
            Data       => \%ValidList,
            SelectedID => $ItemData{ValidID} || $ValidListReverse{valid},
        );

        if ($ItemData{ItemID} eq 'NEW') {
        	my $TempParentId = $Self->{ParamObject}->GetParam( Param => "ParentID" );
        	if ($TempParentId) {
	        	$ItemData{ParentID} = $TempParentId;
	        }
	        else { #Provide the root ID
	        	$ItemData{ParentID} = -1;
	        }
        }

        # output ItemEdit
        $Self->{LayoutObject}->Block(
            Name => 'ItemEdit',
            Data => {
                %ItemData,
                ValidOptionStrg         => $ValidOptionStrg,
            },
        );

        if ( $ItemData{Class} eq 'NEW' ) {

            # output ItemEditClassAdd
            $Self->{LayoutObject}->Block(
                Name => 'ItemEditClassAdd',
                Data => {
                    Class => $ItemData{Class},
                },
            );
        }
        else {

            # output ItemEditClassExist
            $Self->{LayoutObject}->Block(
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
	        my $ItemIDList = $Self->{FieldTreeObject}->ItemListSorted(
	            Valid => 0,
				Class => $ItemData{Class},      
				ParentID=> $ItemData{ItemID}
			);
	

	        $Self->{LayoutObject}->Block(
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
	            my $ChildItemData = $Self->{FieldTreeObject}->ItemGet(
	                ItemID => $ChildItemID,
	            );
	
	            # output overview item list
	            $Self->{LayoutObject}->Block(
	                Name => 'OverviewChildItemList',
	                Data => {
	                    %{$ChildItemData},
	                    CssClass      => $CssClass,
	                    Valid         => $ValidList{ $ChildItemData->{ValidID} },
	                },
	            );
	        }        
			
			
			my $SubFieldaction = $Self->{ParamObject}->GetParam( Param => "SubFieldaction" );
			
			if  (defined($SubFieldaction) && $SubFieldaction eq 'FieldEdit') {

				my %FieldData;
				$FieldData{FieldID} = $Self->{ParamObject}->GetParam( Param => "FieldID" );
		        if ( $FieldData{FieldID} eq 'NEW' ) {
		            # get leaf id
		            $FieldData{FieldTreeID} = $Self->{ParamObject}->GetParam( Param => "ItemID" );
		
		            # redirect to overview
		            return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" )
		                if !$FieldData{FieldTreeID};
		        }
		        else {
		
		            # get item data
		            my $FieldDataRef = $Self->{FieldTreeObject}->FieldGet(
		                FieldID => $FieldData{FieldID},
		            );
		
		            # check item data
		            return $Self->{LayoutObject}->ErrorScreen()
		                if !$FieldDataRef;
		
		            %FieldData = %{$FieldDataRef};
		        }
		        
		        my $checked = '';
		        if ($FieldData{Required}) {
		        	$checked = ' checked';
		        }
				my $FieldTypes = $Self->{FieldTreeObject}->FieldTypes();

		        my $FieldTypesStr  = $Self->{LayoutObject}->BuildSelection(
		            Name       => 'FieldType',
		            Data       => $FieldTypes,
		            SelectedID => $FieldData{FieldType},
		        );
		        
		        
		        
		        my $ClassList       = $Self->{GeneralCatalogObject}->ClassList();
		        my $ClassOptionStrg = $Self->{LayoutObject}->BuildSelection(
		            Name         => 'Template',
		            Data         => $ClassList,
		            SelectedID   => $FieldData{Template},
		            PossibleNone => 1,
		            Translation  => 0,
		        );
		        
		        my %QueueList       = $Self->{QueueObject}->QueueList();
		        my $QueueStr = $Self->{LayoutObject}->BuildSelection(
		            Name         => 'Template',
		            Data         => \%QueueList,
		            SelectedID   => $FieldData{Template},
		            PossibleNone => 1,
		            Translation  => 0,
		        );
		        
		        my $Parent = $Self->{FieldTreeObject}->ItemGet(ItemID=>$FieldData{FieldTreeID});
		        my $FieldDetailsBlock = "FieldDetailsGeneral";
		        if ($Parent->{Class} eq "Templates") {
		            $FieldDetailsBlock = "FieldDetailsTemplates";
		        }
		        
                for (("FieldEdit", $FieldDetailsBlock))
                {
                    
                
		       
		        $Self->{LayoutObject}->Block(
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
		        my $ItemIDList = $Self->{FieldTreeObject}->FieldList(
		            Valid => 0,
					FieldTreeID => $ItemData{ItemID},      
				);
				
		
	
		        $Self->{LayoutObject}->Block(
		               Name => 'OverviewFields',
		               Data => {
		                    ItemID=>$ItemData{ItemID},
		               },
		            );
		        my $CssClass = '';
		        
		my @FieldList;

		for my $FieldID ( keys %{$ItemIDList} ) {
			my $Field = $Self->{FieldTreeObject}->FieldGet(
	                    FieldID => $FieldID,
			);
			push @FieldList, $Field;
		}
		
		for my $ChildItemData ( sort { $a->{Position} <=> $b->{Position} } @FieldList ) {
		
			
			my $ChildItemID = $ChildItemData->{FieldID};
		        
		            # set output class
		            $CssClass = $CssClass eq 'searchactive' ? 'searchpassive' : 'searchactive';
		
		            # get item data
		            my $ChildItemData = $Self->{FieldTreeObject}->FieldGet(
		                FieldID => $ChildItemID,
		            );
		
		            # output overview item list
		            $Self->{LayoutObject}->Block(
		                Name => 'OverviewFieldList',
		                Data => {
		                    %{$ChildItemData},
		                    CssClass      => $CssClass,
		                    Valid         => $ValidList{ $ChildItemData->{ValidID} },
		                },
		            );
		        }


        $Self->{LayoutObject}->Block(
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
		            my $ChildItemData = $Self->{FieldTreeObject}->FieldGet(
		                FieldID => $ChildItemID,
		            );
		
		            # output overview item list
		            $Self->{LayoutObject}->Block(
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
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();
        # create output string
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminFieldTree',
            Data         => \%Param,
        );

        # add footer
        $Output .= $Self->{LayoutObject}->Footer();

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
            $FieldData{$Param} = $Self->{ParamObject}->GetParam( Param => $Param ) || '';
        }
        if ( $FieldData{FieldType} eq "UserInfoFetcher" ) {
            my %FIDs;
            
            for my $Param (qw(Template_UIF_CellularAccountNo Template_UIF_StreetName Template_UIF_PlaceName
                            Template_UIF_AreaName Template_UIF_CountryName)) {
                $FIDs{$Param} = $Self->{ParamObject}->GetParam( Param => $Param ) || '';
            }
            $FieldData{Template} = "$FIDs{Template_UIF_CellularAccountNo};$FIDs{Template_UIF_StreetName};$FIDs{Template_UIF_PlaceName};$FIDs{Template_UIF_AreaName};$FIDs{Template_UIF_CountryName}";
        }
        $FieldData{FieldTreeID} = $Self->{ParamObject}->GetParam( Param => 'ItemID' );
        my $ItemID = $FieldData{FieldTreeID};

        # check class
        return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" )
            if !$FieldData{FieldTreeID};

        # save to database
        my $Success;
        my $FieldID;
        if ( $FieldData{FieldID} eq 'NEW' ) {
            $Success = $Self->{FieldTreeObject}->FieldAdd(
                %FieldData,
                UserID => $Self->{UserID},
            );
            $FieldID = $Success;
        }
        else {
            $Success = $Self->{FieldTreeObject}->FieldUpdate(
                %FieldData,
                UserID => $Self->{UserID},
            );
            $FieldID = $FieldData{FieldID};
        }

        return $Self->{LayoutObject}->ErrorScreen() if !$Success;

        # redirect to overview class list
        return $Self->{LayoutObject}->Redirect(
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
            $ItemData{$Param} = $Self->{ParamObject}->GetParam( Param => $Param ) || '';
        }

        # check class
        return $Self->{LayoutObject}->Redirect( OP => "Action=$Self->{Action}" )
            if !$ItemData{Class} || $ItemData{Class} eq 'NEW';

        # save to database
        my $Success;
        my $ItemID;
        if ( $ItemData{ItemID} eq 'NEW' ) {
            $Success = $Self->{FieldTreeObject}->ItemAdd(
                %ItemData,
                UserID => $Self->{UserID},
            );
            $ItemID = $Success;
        }
        else {
            $Success = $Self->{FieldTreeObject}->ItemUpdate(
                %ItemData,
                UserID => $Self->{UserID},
            );
            $ItemID = $ItemData{ItemID};
        }

        return $Self->{LayoutObject}->ErrorScreen() if !$Success;

        # redirect to overview class list
        return $Self->{LayoutObject}->Redirect(
            OP => "Action=$Self->{Action}&Subaction=ItemEdit&ItemID=$ItemData{ParentID}"
        );
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {

        # get catalog class list
        my $ClassList       = $Self->{FieldTreeObject}->ClassList();
        my $ClassOptionStrg = $Self->{LayoutObject}->BuildSelection(
            Name         => 'Class',
            Data         => $ClassList,
            PossibleNone => 1,
            Translation  => 0,
        );

        # output overview
        $Self->{LayoutObject}->Block(
            Name => 'Overview',
            Data => {
                %Param,
                ClassOptionStrg => $ClassOptionStrg,
            },
        );
        $Self->{LayoutObject}->Block(
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
            $Self->{LayoutObject}->Block(
                Name => 'OverviewClassList',
                Data => {
                    Class    => $Class,
                    CssClass => $CssClass,
                },
            );
        }

        # output header and navbar
        my $Output = $Self->{LayoutObject}->Header();
        $Output .= $Self->{LayoutObject}->NavigationBar();

        # create output string
        $Output .= $Self->{LayoutObject}->Output(
            TemplateFile => 'AdminFieldTree',
            Data         => \%Param,
        );

        # add footer
        $Output .= $Self->{LayoutObject}->Footer();

        return $Output;
    }
}

1;
