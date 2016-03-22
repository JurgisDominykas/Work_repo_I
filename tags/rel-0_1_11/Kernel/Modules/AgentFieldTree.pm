# --
# Kernel/Modules/AdminFieldTree.pm - admin frontend of general catalog management
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: AdminFieldTree.pm,v 1.22 2009/05/18 09:40:46 mh Exp $
# --
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentFieldTree;

use strict;
use warnings;

use Kernel::System::FieldTree;
use Kernel::System::GeneralCatalog;
use Kernel::System::Valid;
use Data::Dumper;


use vars qw($VERSION);
$VERSION = qw($Revision: 1.22 $) [1];

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(ConfigObject ParamObject LogObject LayoutObject ConfigObject QueueObject)) {
        if ( !$Self->{$Object} ) {
            $Self->{LayoutObject}->FatalError( Message => "Got no $Object!" );
        }
    }
    if ($Param{CacheObject}) {
    	$Self->{CacheObject} = $Param{CacheObject}; 
    }
    else {
	    $Self->{CacheObject} = Kernel::System::Cache->new( %Param );
    }
    $Self->{FieldTreeObject}	= Kernel::System::FieldTree->new(%Param);
    $Self->{GeneralCatalogObject}	= Kernel::System::GeneralCatalog->new(%Param);
    $Self->{ValidObject} 		= Kernel::System::Valid->new(%Param);

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    if ( $Self->{Subaction} eq 'ChildsJSON' ) {
	
		my @ItemsOn = $Self->{FieldTreeObject}->TreeJSON(
			ItemID => $Self->{ParamObject}->GetParam( Param => "branch_id" ),
			Class => $Self->{ParamObject}->GetParam( Param => "Class" ),
			ValueSetID => $Self->{ParamObject}->GetParam( Param => "ValueSetID" ),
		);
		
       my $JSON = $Self->{LayoutObject}->JSON(
                    Data         => \@ItemsOn,
	        );
	        
        return $Self->{LayoutObject}->Attachment(
            ContentType => 'text/plain; charset=' . $Self->{LayoutObject}->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );    
    }
    
 	elsif ( $Self->{Subaction} eq 'AjaxFields' ) {
	
	    my $Disabled = $Self->{ParamObject}->GetParam( Param => "Disabled" );	    
	    my $ItemID = $Self->{ParamObject}->GetParam( Param => "ItemID" );
	    my $ValueSetID = $Self->{ParamObject}->GetParam( Param => "ValueSetID" );
	    #my $ReadOnly = $Self->{ParamObject}->GetParam( Param => "ReadOnly" ) || 0;
		my $Prefix = $Self->{ParamObject}->GetParam( Param => "Prefix" ) || "Field_";
		
		my $FieldIDList = $Self->{FieldTreeObject}->FieldList(
                FieldTreeID => $ItemID,
                Valid => 1,
            );
        
		my $ValueSet = {};
		
		if ($ValueSetID) {
			$ValueSet = $Self->{FieldTreeObject}->ValueSetGet(
                ValueSetID => $ValueSetID,
            );
        }
        my $log;
            		
		my $Par;
		my %TimeConfig;
		my $CyclePrefix;
		my @FieldList;
		for my $FieldID ( keys %{$FieldIDList} ) {
			my $Field = $Self->{FieldTreeObject}->FieldGet(
	                    FieldID => $FieldID,
			);
			push @FieldList, $Field;
		}
		
		if ( @FieldList == 0 ) {
			$Self->{LayoutObject}->Block(
	            Name => 'EmptyList',
	        );
		}
		
		for my $Field ( sort { $a->{Position} <=> $b->{Position} } @FieldList ) {
			
			$Par = {};
			%TimeConfig = ();
			my $SelectedStr;
			
			my $FieldID = $Field->{FieldID};
			$CyclePrefix = $Prefix.$FieldID;
			if ($Field->{FieldType} eq "DateTime") {
				# time setting if avialable
				if (!defined($ValueSet->{ $FieldID })) {
					$ValueSet->{ $FieldID } = $Self->{ParamObject}->GetParam( Param => $Prefix.$FieldID );
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
			    	$Par->{DataValue} = $Self->{LayoutObject}->BuildDateSelection(
				        %Param,
				        %TimeConfig,
				        Prefix => $CyclePrefix,
				        Format => 'DateInputFormatLong',
				    );
		        }
			}
			elsif ($Field->{FieldType} eq "Select") {
			    if (!defined($ValueSet->{ $FieldID })) {
					$ValueSet->{ $FieldID } = $Self->{ParamObject}->GetParam( Param => $Prefix.$FieldID );
				}				  				 
    			my $ClassList = $Self->{GeneralCatalogObject}->ItemList( Class => $Field->{Template}, Valid => 1);
    			if (!$Disabled) {
    		        $SelectedStr = $Self->{LayoutObject}->BuildSelection(
    		            Name         => $Prefix.$Field->{FieldID},
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
				$Field->{QueueName} = $Self->{QueueObject}->QueueLookup( 
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
	                Value => $ValueSet->{$FieldID}||$Self->{ParamObject}->GetParam( Param => $Prefix.$FieldID ),
	                RequiredCssClass => defined($Field->{Required}) && $Field->{Required}  ? 'required' : '',
	                CheckedStr => ( (defined($ValueSet->{$FieldID}) && ($ValueSet->{$FieldID} eq 1)) ||$Self->{ParamObject}->GetParam( Param => $Prefix.$FieldID )) ? ' checked ' : '',
	                SelectedStr => $SelectedStr,
		            #Disabled => $Disabled,
		            Disabled => ($Disabled ? 'Disabled' : ''),
		            FieldPrefix => $Self->{ParamObject}->GetParam( Param => "DynamicFieldName" )
	            };
	            
				$Self->{LayoutObject}->Block(
		            Name => 'Field',
		            Data => $Data,
		        );
			    $Self->{LayoutObject}->Block(
		            Name => $Field->{FieldType},
		            Data => $Data,
		        );
			    $Self->{LayoutObject}->Block(
		            Name => $Field->{FieldType}. ($Disabled ? 'Disabled' : 'Enabled'),
		            Data => $Data,
		        );
			}
		}
	# display load validator block one time to make sure that fields are loadedd correctly
	$Self->{LayoutObject}->Block(
            Name => 'LoadValidator',
        );
			        
        my $Output = $Self->{LayoutObject}->Output(
            TemplateFile => 'FieldTreeFields',
            Data         => {
            					%Param,
            					ValueSetID => 'NEW'
            				}
        );
        
        return $Output;

    }
 	elsif ( $Self->{Subaction} eq 'AjaxFieldsSearch' ) {
	
	    my $ItemID = $Self->{ParamObject}->GetParam( Param => "ItemID" );
		my $Prefix = $Self->{ParamObject}->GetParam( Param => "Prefix" ) || "Field_";
	
		
		my $FieldIDList = $Self->{FieldTreeObject}->FieldList(
                FieldTreeID => $ItemID,
                Valid => 1,
            );
        
		my $Par;
		my @FieldList;

		for my $FieldID ( keys %{$FieldIDList} ) {
			my $Field = $Self->{FieldTreeObject}->FieldGet(
	                    FieldID => $FieldID,
			);
			push @FieldList, $Field;
		}
		
		for my $Field ( sort { $a->{Position} <=> $b->{Position} } @FieldList ) {
		
			$Par = {};
			my $SelectedStr;
			my $FieldID = $Field->{FieldID};


			if ($Field->{FieldType} eq "DateTime") {
				$Param{$Prefix.$FieldID.'FromYear'}=$Self->{ConfigObject}->Get("FieldTree::Search::FromYear");
				    $Par->{DataValue} = '<label>From: </label>'.$Self->{LayoutObject}->BuildDateSelection(
				        %Param,
				        Prefix => $Prefix.$FieldID.'From',
				        Format => 'DateInputFormatLong',
				    ).'<br>'.'<label>To: </label>'.$Self->{LayoutObject}->BuildDateSelection(
				        %Param,
				        Prefix => $Prefix.$FieldID.'To',
				        Format => 'DateInputFormatLong',
				    );
			}
			elsif ($Field->{FieldType} eq "Select") {
				my $ClassList = $Self->{GeneralCatalogObject}->ItemList( Class => $Field->{Template}, Valid => 1);
		        $SelectedStr = $Self->{LayoutObject}->BuildSelection(
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

				$Self->{LayoutObject}->Block(
			            Name => 'Field',
			            Data => {
			            	%{$Par},
			                %{$Field},
			                Value => '',
			                RequiredCssClass => $Field->{Required} ? 'required' : '',
			                SelectedStr => $SelectedStr,
			            },
			        );
				$Self->{LayoutObject}->Block(
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
		        
        my $Output = $Self->{LayoutObject}->Output(
            TemplateFile => 'FieldTreeFieldsSearch',
            Data         => {
            					%Param,
            					ValueSetID => 'NEW'
            }
        );
        
        return $Output;
    }
 	elsif ( $Self->{Subaction} eq 'AjaxFieldsSave' ) {
	
		my $Success =  $Self->{LayoutObject}->ValueSetFromPOST( %Param );
#        return $Self->{LayoutObject}->ErrorScreen() if !$Success;
		return "OK";
        # redirect to overview class list
#        return $Self->{LayoutObject}->Redirect(
#            OP => "Action=$Self->{Action}&Subaction=ItemEdit&ItemID=$ItemID"
#        );
    }
    elsif ( $Self->{Subaction} eq 'AjaxClientInfoExtended' ) {
        my $AccountNumber = $Self->{ParamObject}->GetParam( Param => "AccountNumber" );
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
        my $JSON = $Self->{LayoutObject}->JSON(
            Data  => \%ret );
        return $Self->{LayoutObject}->Attachment(
            ContentType => 'text/plain; charset=' . $Self->{LayoutObject}->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );   
    }
    elsif ( $Self->{Subaction} eq 'AjaxCommentsTemplates' ) {
	    my $Result = "";
		my $JSON;
		my $JSONResult;
	    if ($Self->{CacheObject}) {
	    	$Result = $Self->{CacheObject}->Get(
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
	        
	        my $SMS = $Self->{FieldTreeObject}->ItemGet(
	            Class => 'Templates',
	            Name  => 'SMS',
	    	);
	    	
	    	if ($SMS) { 
	    		    	
		    	my $SMSTemplatesGroups = $Self->{FieldTreeObject}->ItemList(
			        Class    => 'Templates',
			        ParentID => $SMS->{ItemID},	        
			    );
			    	    
			    my %TemplatesGroups;	    
			    while ((my $STGItemID, my $STGName) = each(%$SMSTemplatesGroups)){
			        
			        
			        my $SubGroups = $Self->{FieldTreeObject}->ItemList(
			              Class    => 'Templates',
			              ParentID => $STGItemID,		        
			        );
			        my %TemplatesSubGroups;
			        while ((my $STSGItemID, my $STSGName) = each(%$SubGroups)) {
			        	
			        	my $SMSTemplates = $Self->{FieldTreeObject}->FieldList(
	                        FieldTreeID => $STSGItemID,
	                    );
	                    my %Templates;
	                    while ((my $STFieldID, my $STFieldName) = each(%$SMSTemplates)) {
	                        my $SMSTemplate = $Self->{FieldTreeObject}->FieldGet(
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
			
			my $Webcare = $Self->{FieldTreeObject}->ItemGet(
	            Class => 'Templates',
	            Name  => 'Webcare',
	    	);
	    	
	    	if ($Webcare) {
	    	
		    	my $WebcareTemplatesGroups = $Self->{FieldTreeObject}->ItemList(
			        Class         => 'Templates',
			        ParentID => $Webcare->{ItemID},	        
			    );
			    	    
			    my %TemplatesGroups;	    
			    while ((my $STGItemID, my $STGName) = each(%$WebcareTemplatesGroups)){
			        
			        
			        	        
			        my $WebcareTemplates = $Self->{FieldTreeObject}->FieldList(
				        FieldTreeID => $STGItemID,
				    );
				    my %Templates;
				    while ((my $STFieldID, my $STFieldName) = each(%$WebcareTemplates)) {
				        my $WebcareTemplate = $Self->{FieldTreeObject}->FieldGet(
					        FieldID  => $STFieldID,
					    );
					    $Templates{$WebcareTemplate->{Name}} = $WebcareTemplate->{Template};			    
					    
				    }		        
			        
			        $TemplatesGroups{$STGName} = \%Templates;	                
				    
				}
				$CommentsTemplates{Webcare} = \%TemplatesGroups;
			
	    	}
					
		  	
	        $JSON = $Self->{LayoutObject}->JSON(
	            Data  => \%CommentsTemplates );

	        $JSONResult = $Self->{LayoutObject}->Attachment(
	            ContentType => 'application/json; charset=' . $Self->{LayoutObject}->{Charset},
	            Content     => $JSON,
	            Type        => 'inline',
	        );

	        
			if ($Self->{CacheObject}) {
			   	$Result = $Self->{CacheObject}->Set(
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
    