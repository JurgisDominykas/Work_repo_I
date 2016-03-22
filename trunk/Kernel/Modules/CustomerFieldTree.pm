# --
# Kernel/Modules/AdminFieldTree.pm - admin frontend of general catalog management
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: AdminFieldTree.pm,v 1.22 2009/05/18 09:40:46 mh Exp $
# --
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::CustomerFieldTree;

use strict;
use warnings;

our @ObjectDependencies = (
	'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Web::Request',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::Cache',
    'Kernel::System::Log',
    'Kernel::System::FieldTree',
    'Kernel::System::Valid',
    'Kernel::System::Queue',
);


use Data::Dumper;


use vars qw($VERSION);
$VERSION = qw($Revision: 1.22 $) [1];

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    if ( $Self->{Subaction} eq 'ChildsJSON' ) {
	
		my @ItemsOn = $Kernel::OM->Get('Kernel::System::FieldTree')->TreeJSON(
			ItemID => $ParamObject->GetParam( Param => "branch_id" ),
			Class => $ParamObject->GetParam( Param => "Class" ),
			ValueSetID => $ParamObject->GetParam( Param => "ValueSetID" ),
		);
		
       my $JSON = $LayoutObject->JSON(
                    Data         => \@ItemsOn,
	        );
	        
        return $LayoutObject->Attachment(
            ContentType => 'text/plain; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );    
    }
    
 	elsif ( $Self->{Subaction} eq 'AjaxFields' ) {
	
	    my $Disabled = $ParamObject->GetParam( Param => "Disabled" );	    
	    my $ItemID = $ParamObject->GetParam( Param => "ItemID" );
	    my $ValueSetID = $ParamObject->GetParam( Param => "ValueSetID" );
		my $Prefix = $ParamObject->GetParam( Param => "Prefix" ) || "Field_";
		my $DoNotShowWarnings = $ParamObject->GetParam( Param => "DoNotShowWarnings" ) || 0;
		
		my $FieldIDList = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldList(
                FieldTreeID => $ItemID,
                Valid => 1,
            );
        
		my $ValueSet = {};
		
		if ( $ValueSetID !~ /new/i ) {
			$ValueSet = $Kernel::OM->Get('Kernel::System::FieldTree')->ValueSetGet(
                ValueSetID => $ValueSetID,
            );
        }
        my $log;
            		
		my $Par;
		my %TimeConfig;
		my $CyclePrefix;
		my @FieldList;
		for my $FieldID ( keys %{$FieldIDList} ) {
			my $Field = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldGet(
                FieldID => $FieldID,
			);
			push @FieldList, $Field;
		}
		
        
        # If branch has no fields, shows error message and generates hidden input
        if ( @FieldList == 0 ) {
            # Does not show error unless $DoNotShowWarnings is false
            if ( !$DoNotShowWarnings )
            {
                $LayoutObject->Block(
                    Name => 'EmptyList',
                );
            }
            $LayoutObject->Block(
                Name => 'NoFieldsLoaded',
            );
        }
        
        my $UncheckedFieldValues = {};
        my $Counter = 0;
		
		my $DynamicFieldPrefix = $ParamObject->GetParam( Param => "DynamicFieldName" );
		
		for my $Field ( sort { $a->{Position} <=> $b->{Position} } @FieldList ) {
			
			$Par = {};
			%TimeConfig = ();
			my $SelectedStr;
			my $FieldID = $Field->{FieldID};
			
			$CyclePrefix = $Prefix.$FieldID;
			if ($Field->{FieldType} eq "DateTime") {
				# time setting if avialable
				if (!defined($ValueSet->{ $FieldID })) {
					$ValueSet->{ $FieldID } = $ParamObject->GetParam( Param => $Prefix.$FieldID );
				}
				
		        if (
		            $ValueSet->{ $FieldID }
		            && $ValueSet->{ $FieldID } =~ m{^(\d\d\d\d)-(\d\d)-(\d\d)\s(\d\d):(\d\d):(\d\d)$}xi
		            )
		        {
		            $TimeConfig{ $CyclePrefix . 'Year' }   = $1;
		            $TimeConfig{ $CyclePrefix . 'Month' }  = $2;
		            $TimeConfig{ $CyclePrefix . 'Day' }    = $3;
		            $TimeConfig{ $CyclePrefix . 'Hour' }   = $4;
		            $TimeConfig{ $CyclePrefix . 'Minute' } = $5;
		            $TimeConfig{ $CyclePrefix . 'Second' } = $6;
		        }
		        
		        if ($Disabled) {
			        $Par->{DataValue} = $ValueSet->{ $FieldID };
		        }
		        else {
			    	$Par->{DataValue} = $LayoutObject->BuildDateSelection(
				        %Param,
				        %TimeConfig,
				        Prefix => $CyclePrefix,
				        Format => 'DateInputFormatLong',
				    );
		        }
			}
			elsif ($Field->{FieldType} eq "Select") {
			    if (!defined($ValueSet->{ $FieldID })) {
					$ValueSet->{ $FieldID } = $ParamObject->GetParam( Param => $Prefix.$FieldID );
				}				  				 
    			my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList( Class => $Field->{Template}, Valid => 1);
    			if (!$Disabled) {
    		        $SelectedStr = $LayoutObject->BuildSelection(
    		            Name         => $DynamicFieldPrefix.'_Field_'.$Field->{FieldID},
    		            SelectedID   => $ValueSet->{$FieldID},
    		            Data         => $ClassList,
    		            PossibleNone => 1,
    		            Translation  => 0,
    		            Disabled => $Disabled,
    		            Class => $Field->{Required} ? 'required validate-select' : '',
    		        );    		        
				} else {				    
				    $SelectedStr = $ClassList->{$ValueSet->{ $FieldID }};
				};
				
			}
			elsif ($Field->{FieldType} eq "Information") {
				$Field->{FieldClass} = 'full';
			}
			elsif ($Field->{FieldType} eq "RuleEscalateTo") {
				$Field->{QueueName} = $Kernel::OM->Get('Kernel::System::Queue')->QueueLookup( 
                        QueueID => $Field->{Template},
                    );
			}
			
			my $Display = 1;		
			for (qw[RuleComment RuleProblemSource RuleProblemReason RuleSLA RuleCompensation ]) {
				if ($Field->{FieldType} eq $_) {
					$Display = 0;
				}
			}
		
			if ($Display && $Field) 
			{
				my $Data = {
	            	%{$Par},
	                %{$Field},
	                Value => $ValueSet->{$FieldID}||$ParamObject->GetParam( Param => $DynamicFieldPrefix."_Field_".$FieldID ),
	                RequiredCssClass => defined($Field->{Required}) && $Field->{Required}  ? 'required' : '',
	                CheckedStr => ( (defined($ValueSet->{$FieldID}) && ($ValueSet->{$FieldID} eq 1)) ||$ParamObject->GetParam( Param => $Prefix.$FieldID )) ? ' checked ' : '',
	                SelectedStr => $SelectedStr,
		            #Disabled => $Disabled,
		            Disabled => ($Disabled ? 'Disabled' : ''),
		            FieldPrefix => $DynamicFieldPrefix,
	            };
	            
	            
				$LayoutObject->Block(
		            Name => 'Field',
		            Data => $Data,
		        );
			    $LayoutObject->Block(
		            Name => $Field->{FieldType},
		            Data => $Data,
		        );
			    $LayoutObject->Block(
		            Name => $Field->{FieldType}. ($Disabled ? 'Disabled' : 'Enabled'),
		            Data => $Data,
		        );
			}
		}
	# display load validator block one time to make sure that fields are loadedd correctly
	$LayoutObject->Block(
            Name => 'LoadValidator',
        );
			        
        my $Output = $LayoutObject->Output(
            TemplateFile => 'FieldTreeFields',
            Data         => {
            					%Param,
            					ValueSetID => 'NEW'
            				}
        );
        
        return $Output;

    }
 	elsif ( $Self->{Subaction} eq 'AjaxFieldsSearch' ) {
	
	    my $ItemID = $ParamObject->GetParam( Param => "ItemID" );
		my $Prefix = $ParamObject->GetParam( Param => "Prefix" ) || "Field_";
	
		
		my $FieldIDList = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldList(
                FieldTreeID => $ItemID,
                Valid => 1,
            );
        
		my $Par;
		my @FieldList;

		for my $FieldID ( keys %{$FieldIDList} ) {
			my $Field = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldGet(
	                    FieldID => $FieldID,
			);
			push @FieldList, $Field;
		}
		
		for my $Field ( sort { $a->{Position} <=> $b->{Position} } @FieldList ) {
		
			$Par = {};
			my $SelectedStr;
			my $FieldID = $Field->{FieldID};


			if ($Field->{FieldType} eq "DateTime") {
				$Param{$Prefix.$FieldID.'FromYear'}=$Kernel::OM->Get('Kernel::Config')->Get("FieldTree::Search::FromYear");
				    $Par->{DataValue} = '<label>From: </label>'.$LayoutObject->BuildDateSelection(
				        %Param,
				        Prefix => $Prefix.$FieldID.'From',
				        Format => 'DateInputFormatLong',
				    ).'<br>'.'<label>To: </label>'.$LayoutObject->BuildDateSelection(
				        %Param,
				        Prefix => $Prefix.$FieldID.'To',
				        Format => 'DateInputFormatLong',
				    );
			}
			elsif ($Field->{FieldType} eq "Select") {
				my $ClassList = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList( Class => $Field->{Template}, Valid => 1);
		        $SelectedStr = $LayoutObject->BuildSelection(
		            Name         => $Prefix.$FieldID,
#		            SelectedID   => $ValueSet->{$FieldID},
		            Data         => $ClassList,
		            PossibleNone => 1,
		            Translation  => 0,
		            
		        );
				
			}
			
			my $Display = 1;		
			for (qw[RuleEscalateTo RuleComment RuleProblemSource RuleProblemReason RuleSLA RuleCompensation ]) {
				if ($Field->{FieldType} eq $_) {
					$Display = 0;
				}
			}
		
			if ($Display) {

				$LayoutObject->Block(
			            Name => 'Field',
			            Data => {
			            	%{$Par},
			                %{$Field},
			                Value => '',
			                RequiredCssClass => $Field->{Required} ? 'required' : '',
			                SelectedStr => $SelectedStr,
			            },
			        );
				$LayoutObject->Block(
			            Name => $Field->{FieldType},
			            Data => {
			            	%{$Par},
			                %{$Field},
			                Value => '',
			                RequiredCssClass => $Field->{Required} ? 'required' : '',
			                SelectedStr => $SelectedStr,
			            },
			        );
			}

		}
		        
        my $Output = $LayoutObject->Output(
            TemplateFile => 'FieldTreeFieldsSearch',
            Data         => {
            					%Param,
            					ValueSetID => 'NEW'
            }
        );
        
        return $Output;
    }
 	elsif ( $Self->{Subaction} eq 'AjaxFieldsSave' ) {
	
		my $Success =  $LayoutObject->ValueSetFromPOST( %Param );
#        return $LayoutObject->ErrorScreen() if !$Success;
		return "OK";
        # redirect to overview class list
#        return $LayoutObject->Redirect(
#            OP => "Action=$Self->{Action}&Subaction=ItemEdit&ItemID=$ItemID"
#        );
    }
    elsif ( $Self->{Subaction} eq 'AjaxClientInfoExtended' ) {
        my $AccountNumber = $ParamObject->GetParam( Param => "AccountNumber" );
        my $info;
        if (defined $AccountNumber) {
            $info = $Self->{AKSEMailTicketObject}->ClientInfoExtendedRetrieve(
                AccountNumber => $AccountNumber,
                UserID => $Self->{UserID}
            );
        }
        
        my %ret = (
            CellularAccountNumber => defined $info->{CellularAccountNumber} ? $info->{CellularAccountNumber} : "",
            StreetName => defined $info->{StreetName} ? $info->{StreetName} : "",
            PlaceName => defined $info->{PlaceName} ? $info->{PlaceName} : "",
            AreaName => defined $info->{AreaName} ? $info->{AreaName} : "",
            CountryName => defined $info->{CountryName} ? $info->{CountryName} : "",
        );
        my $JSON = $LayoutObject->JSON(
            Data  => \%ret );
        return $LayoutObject->Attachment(
            ContentType => 'text/plain; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );   
    }
    elsif ( $Self->{Subaction} eq 'AjaxCommentsTemplates' ) {
	    my $Result = "";
		my $JSON;
		my $JSONResult;
	    if ($Kernel::OM->Get('Kernel::System::Cache')) {
	    	$Result = $Kernel::OM->Get('Kernel::System::Cache')->Get(
		    		Type	=> 'FieldTree',
					Key => 'AjaxCommentsTemplates',
	    	);
	    }
	    if ($Result) {
	    	$JSONResult = $Result;
		}
		else {
	    
	        
	        my %CommentsTemplates;
	        
	        
	        # Get SMS templates
	        
	        my $SMS = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemGet(
	            Class => 'Templates',
	            Name  => 'SMS',
	    	);
	    	
	    	if ($SMS) { 
	    		    	
		    	my $SMSTemplatesGroups = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemList(
			        Class    => 'Templates',
			        ParentID => $SMS->{ItemID},	        
			    );
			    	    
			    my %TemplatesGroups;	    
			    while ((my $STGItemID, my $STGName) = each(%$SMSTemplatesGroups)){
			        
			        
			        my $SubGroups = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemList(
			              Class    => 'Templates',
			              ParentID => $STGItemID,		        
			        );
			        my %TemplatesSubGroups;
			        while ((my $STSGItemID, my $STSGName) = each(%$SubGroups)) {
			        	
			        	my $SMSTemplates = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldList(
	                        FieldTreeID => $STSGItemID,
	                    );
	                    my %Templates;
	                    while ((my $STFieldID, my $STFieldName) = each(%$SMSTemplates)) {
	                        my $SMSTemplate = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldGet(
	                            FieldID  => $STFieldID,
	                        );
	                        $Templates{$SMSTemplate->{Name}} = $SMSTemplate->{Template};                               
	                   }               
	               
	                   $TemplatesSubGroups{$STSGName} = \%Templates;
			        }
	                
				    $TemplatesGroups{$STGName} = \%TemplatesSubGroups;
				}
				$CommentsTemplates{SMS} = \%TemplatesGroups;	
			
	    	}
			
			# Get Webcare templates
			
			my $Webcare = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemGet(
	            Class => 'Templates',
	            Name  => 'Webcare',
	    	);
	    	
	    	if ($Webcare) {
	    	
		    	my $WebcareTemplatesGroups = $Kernel::OM->Get('Kernel::System::FieldTree')->ItemList(
			        Class         => 'Templates',
			        ParentID => $Webcare->{ItemID},	        
			    );
			    	    
			    my %TemplatesGroups;	    
			    while ((my $STGItemID, my $STGName) = each(%$WebcareTemplatesGroups)){
			        
			        
			        	        
			        my $WebcareTemplates = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldList(
				        FieldTreeID => $STGItemID,
				    );
				    my %Templates;
				    while ((my $STFieldID, my $STFieldName) = each(%$WebcareTemplates)) {
				        my $WebcareTemplate = $Kernel::OM->Get('Kernel::System::FieldTree')->FieldGet(
					        FieldID  => $STFieldID,
					    );
					    $Templates{$WebcareTemplate->{Name}} = $WebcareTemplate->{Template};			    
					    
				    }		        
			        
			        $TemplatesGroups{$STGName} = \%Templates;	                
				    
				}
				$CommentsTemplates{Webcare} = \%TemplatesGroups;
			
	    	}
					
		  	
	        $JSON = $LayoutObject->JSON(
	            Data  => \%CommentsTemplates );

	        $JSONResult = $LayoutObject->Attachment(
	            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
	            Content     => $JSON,
	            Type        => 'inline',
	        );

	        
			if ($Kernel::OM->Get('Kernel::System::Cache')) {
			   	$Result = $Kernel::OM->Get('Kernel::System::Cache')->Set(
			    		Type	=> 'FieldTree',
						Key => 'AjaxCommentsTemplates',
						Value => $JSONResult,    		
			    	);
		     }
	    }

        return $JSONResult;
    }   
}

1;
    