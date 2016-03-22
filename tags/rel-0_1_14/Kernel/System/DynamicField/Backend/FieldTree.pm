# --
# Kernel/System/DynamicField/Backend/FieldTree.pm - Delegate for DynamicField FieldTree backend
# Copyright (C) 2012 Atviro kodo sprendimai, http://www.aksprendimai.lt/
# --
# $Id: FieldTree.pm,v 1.48.2.4 2012/05/07 21:43:10 cr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::Backend::FieldTree;

use strict;
use warnings;

use Data::Dumper;
use Kernel::System::VariableCheck qw(:all);
use Kernel::System::DynamicFieldValue;
use Kernel::System::DynamicField::Backend::BackendCommon;
use Kernel::System::GeneralCatalog;
use Kernel::Output::HTML::Layout;
use Kernel::System::FieldTree;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.48.2.4 $) [1];

=head1 NAME

Kernel::System::DynamicField::Backend::FieldTree

=head1 SYNOPSIS

DynamicFields FieldTree backend delegate

=head1 PUBLIC INTERFACE

This module implements the public interface of L<Kernel::System::DynamicField::Backend>.
Please look there for a detailed reference of the functions.

=over 4

=item new()

usually, you want to create an instance of this
by using Kernel::System::DynamicField::Backend->new();

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (qw(ConfigObject EncodeObject LogObject MainObject DBObject TimeObject )) {
        die "Got no $Needed!" if !$Param{$Needed};

        $Self->{$Needed} = $Param{$Needed};
    }
    
    $Self->{DynamicFieldValueObject} = Kernel::System::DynamicFieldValue->new( %{$Self} );
    $Self->{FieldTreeObject} = Kernel::System::FieldTree->new( %{$Self} );
    $Self->{GeneralCatalogObject} = Kernel::System::GeneralCatalog->new( %{$Self} );
    $Self->{BackendCommonObject} = Kernel::System::DynamicField::Backend::BackendCommon->new( %{$Self} );

    # set the maximum lenght for the FieldTree fields to still be a searchable field in some
    # databases
    $Self->{MaxLength} = 3800;# FIXME: delete

    return $Self;
}

sub ValueGet {
    my ( $Self, %Param ) = @_;

            
    my $DFValue = $Self->{DynamicFieldValueObject}->ValueGet(
        FieldID  => $Param{DynamicFieldConfig}->{ID},
        ObjectID => $Param{ObjectID},
    );

    return if !$DFValue;
    return if !IsArrayRefWithData($DFValue);
    return if !IsHashRefWithData( $DFValue->[0] );
    
    my $Value;
    $Value->{ValueSetID} = $DFValue->[0]->{ValueInt};
    return $Value;
}

sub ValueSet {
    my ( $Self, %Param ) = @_;
    
    my $ValueSetID;
    if ($Param{Value}->{ValueSetID} eq "NEW")
    {
        my $Result = $Self->{FieldTreeObject}->ValueSetAdd(Data => $Param{Value}->{FieldsValues});
        $ValueSetID = $Result->{ValueSetID};
    }   

    my $Success = $Self->{DynamicFieldValueObject}->ValueSet(
        FieldID  => $Param{DynamicFieldConfig}->{ID},
        ObjectID => $Param{ObjectID},
        Value    => [
            {
                ValueInt => $ValueSetID,
            },
        ],
        UserID => $Param{UserID},
    );
    
    if ( $Param{DynamicFieldConfig}->{ObjectType} eq 'Ticket' ) {
        return if !$Self->{FieldTreeObject}->RulesPostProcess(
            TicketID   => $Param{ObjectID},
            UserID     => $Param{UserID},
            ValueSetID => $ValueSetID,
        );
    }

    return $Success;
}

sub ValueDelete {
    my ( $Self, %Param ) = @_;

    my $Success = $Self->{DynamicFieldValueObject}->ValueDelete(
        FieldID  => $Param{DynamicFieldConfig}->{ID},
        ObjectID => $Param{ObjectID},
        UserID   => $Param{UserID},
    );

    return $Success;
}

sub AllValuesDelete {
    my ( $Self, %Param ) = @_;

    my $Success = $Self->{DynamicFieldValueObject}->AllValuesDelete(
        FieldID => $Param{DynamicFieldConfig}->{ID},
        UserID  => $Param{UserID},
    );

    return $Success;
}

sub ValueValidate {
    my ( $Self, %Param ) = @_;

    my $Success = $Self->{DynamicFieldValueObject}->ValueValidate(
        Value => {
            ValueText => $Param{Value},
        },
        UserID => $Param{UserID}
    );
    # FIXME: visada success?

    return $Success;
}

sub SearchSQLGet {
    my ( $Self, %Param ) = @_;

    if ( $Param{Operator} eq 'Equals' ) {
        my $SQL = " $Param{TableAlias}.value_int IN ( SELECT value_set_id FROM field_tree_value WHERE field_tree_id = ".$Self->{DBObject}->Quote( $Param{SearchTerm}.' ) ' );
        return $SQL;
    }


    $Self->{'LogObject'}->Log(
        'Priority' => 'error',
        'Message'  => "Unsupported Operator $Param{Operator}",
    );

    return;
}

sub SearchSQLOrderFieldGet {
    my ( $Self, %Param ) = @_;

    return "$Param{TableAlias}.value_int";
}

sub EditFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldName   = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    $Param{FieldName} = $FieldName; 
    my $FieldLabel  = $Param{DynamicFieldConfig}->{Label};

    my $HTMLString = "";
    my $Value = '';

    # set the field value or default
    if ( $Param{UseDefaultValue} ) {
        $Value = ( defined $FieldConfig->{DefaultValue} ? $FieldConfig->{DefaultValue} : '' );
    }
    $Value = $Param{Value} if defined $Param{Value};

    

    # extract the dynamic field value form the web request
    my $FieldValue = $Self->EditFieldValueGet(
        %Param,
    );

    # set values from ParamObject if present
    if ( $FieldValue->{ValueSetID} && $FieldValue->{ValueSetID} !~ /new/i ) {
        $Value = $FieldValue;
    }

    # set the rows number
    my $RowsNumber = defined $FieldConfig->{Rows} && $FieldConfig->{Rows} ? $FieldConfig->{Rows} : '7';

    # set the cols number
    my $ColsNumber
        = defined $FieldConfig->{Cols} && $FieldConfig->{Cols} ? $FieldConfig->{Cols} : '42';

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldFieldTree';
    if ( defined $Param{Class} && $Param{Class} ne '' ) {
        $FieldClass .= ' ' . $Param{Class};
    }

    # set field as mandatory
    $FieldClass .= ' Validate_Required' if $Param{Mandatory};

    # set error css class
    $FieldClass .= ' ServerError' if $Param{ServerError};

    # set validation class for maximum characters
    $FieldClass .= ' Validate_MaxLength';

    # create field HTML
    # the XHTML definition does not support maxlenght attribute for a FieldTree field, therefore
    # is nedded to be set by JS code (otherwise wc3 validator will complaint about it)
    # notice that some browsers count new lines \n\r as only 1 character in this cases the
    # validation framework might rise an error while the user is still capable to enter text in the
    # FieldTree, otherwise the maxlenght property will prevent to enter more text than the maximum
    
    if ($Param{ParamObject}) {
        my $LayoutObject = Kernel::Output::HTML::Layout->new( %Param, %{$Self} );

        my %GetParam;
        for my $Key (qw(ProblemTypeID)) {
            $GetParam{$Key} = $Param{ParamObject}->GetParam( Param => $Key );
        }

        if ($Value && $Value->{ValueSetID} )  {
            if (!$GetParam{ProblemTypeID}) {
                $Param{FieldTreeID} = $Self->{FieldTreeObject}->ValueSetGetFieldTreeID(
                    ValueSetID => $Value->{ValueSetID},
                );
            }
        }
        else {
            $Value = {};
            $Value->{ValueSetID} = "NEW";
        }
            
        my @FieldTreeStructure = $Self->{FieldTreeObject}->JSON(
            ItemID => $Self->{ConfigObject}->Get("FieldTree::ProblemTypeRootFieldTreeID"),
            Class => $Self->{ConfigObject}->Get("FieldTree::ProblemTypeClass"),
            ValueSetID => $Value->{ValueSetID},
            FieldTreeID => $GetParam{ProblemTypeID},
        );
        
        if ($Value->{ValueSetID} eq "NEW")
        {
        
            $LayoutObject->Block(
                Name => 'FieldTree',
                Data => {
                    %Param,
                    ValueSetID => $Value->{ValueSetID},
                    MandatoryFieldTreeClass => $Param{Mandatory} == '1' ? 'Validate_Required' : ''
                },
            );

            for my $Row (@FieldTreeStructure) {
                $LayoutObject->Block(
                    Name => 'FieldTreeLevel1',
                    Data => {
                       # FT => Dumper(\@FieldTreeStructure),
                        %Param,
                        %{$Row},
                        CSSOpenClass => $Row->{open} ? 'open' : '',
                    },
                );
                my $FieldIDList = $Self->{FieldTreeObject}->FieldList(
                    FieldTreeID => $Row->{id},
                    Valid => 1,
                );
                
                if (scalar @{ $Row->{items} } == 0 && ( keys %{$FieldIDList} ) == 0)
                {
                    $LayoutObject->Block(
                        Name => 'EmptyBranch',
                        Data => {},
                    );
                }
                for my $ChildrenRow (@{ $Row->{items} }) {
                    $LayoutObject->Block(
                        Name => 'FieldTreeLevel2',
                        Data => {
                            %Param,
                            %{$ChildrenRow},
                            CSSOpenClass => $ChildrenRow->{open} ? 'open' : '',
                        },
                    );
                }
            }
        }
        else
        {
            
            $Param{ItemRecursiveName} = $Self->{FieldTreeObject}->ItemRecursiveName(
                ItemID => $Param{FieldTreeID},
            );
            
            $LayoutObject->Block(
                    Name => 'FieldTreePreview',
                    Data => {
                        %Param,
                        ValueSetID => $Value->{ValueSetID},
                    },
                );
                $LayoutObject->Block(
                    Name => 'FieldTreeRecursiveName',
                    Data => {
                        %Param,
                        ValueSetID => $Value->{ValueSetID},
                    },
                );
            
            
        }
            
        $HTMLString .= $LayoutObject->Output(
            TemplateFile => 'DynamicFieldFieldTree',
            Data         => {
                      %Param,
            }
        );
    }

    # for client side validation
    my $DivID = $FieldName . 'Error';

    if ( $Param{Mandatory} ) {
        $HTMLString .= <<"EOF";
    <div id="$DivID" class="TooltipErrorMessage">
        <p>
            \$Text{"This field is required or The field content is too long! Maximum size is $Self->{MaxLength} characters."}
        </p>
    </div>
EOF
    }
    else {
        $HTMLString .= <<"EOF";
    <div id="$DivID" class="TooltipErrorMessage">
        <p>
            \$Text{"The field content is too long! Maximum size is $Self->{MaxLength} characters."}
        </p>
    </div>
EOF
    }

    if ( $Param{ServerError} ) {

        my $ErrorMessage = $Param{ErrorMessage} || 'This field is required.';
        my $DivID = $FieldName . 'ServerError';

        # for server side validation
        $HTMLString .= <<"EOF";
    <div id="$DivID" class="TooltipErrorMessage">
        <p>
            \$Text{"$ErrorMessage"}
        </p>
    </div>
EOF
    }

    # call EditLabelRender on the common backend
    my $LabelString = $Self->{BackendCommonObject}->EditLabelRender(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        Mandatory          => $Param{Mandatory} || '0',
        FieldName          => $FieldName,
    );

    my $Data = {
        Field => $HTMLString,
        Label => $LabelString,
    };

    return $Data;
}

sub EditFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldTreeIdName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name} . '_FieldTreeID';

    my $Value = {};

    # check if there is a Template and retreive the dynamic field value from there
    if ( IsHashRefWithData( $Param{Template} ) ) {
        $Value = $Param{Template}->{$FieldName};
    }

    # otherwise get dynamic field value form param
    else {
        $Value->{ValueSetID} = $Param{ParamObject}->GetParam( Param => $FieldName ); 
    }

    if ( defined $Param{ReturnTemplateStructure} && $Param{ReturnTemplateStructure} eq '1' ) {
        return {
            $FieldName => $Value,
        };
    }
    
    my $FieldTreeID = $Param{ParamObject}->GetParam(Param => $FieldTreeIdName);
    if (!$FieldTreeID) {
        return 
    }
    
    my $FieldsValues;
    if(defined($FieldTreeID)) {
        $FieldsValues = $Self->{FieldTreeObject}->GetFieldsValues(
            %Param,
            'FieldTreeID' => $FieldTreeID,
            'Prefix' => 'DynamicField_' . $Param{DynamicFieldConfig}->{Name}
        );
    }
    
    $Value->{FieldsValues} = $FieldsValues;

    # for this field the normal return an the ReturnValueStructure are the same
    return $Value;
}

sub EditFieldValueValidate {
    my ( $Self, %Param ) = @_;

    # get the field value from the http request
    my $Value = $Self->EditFieldValueGet(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        ParamObject        => $Param{ParamObject},

        # not necessary for this backend but place it for consistency reasons
        ReturnValueStructure => 1,
    );

    my $ServerError;
    my $ErrorMessage;

    # perform necessary validations
    if ( $Param{Mandatory} && $Value eq '' ) {
        $ServerError = 1;
    }

    if ( length $Value > $Self->{MaxLength} ) {
        $ServerError = 1;
        $ErrorMessage
            = "The field content is too long! Maximum size is $Self->{MaxLength} characters.";
    }

    # create resulting structure
    my $Result = {
        ServerError  => $ServerError,
        ErrorMessage => $ErrorMessage,
    };

    return $Result;
}

sub DisplayValueRender {
    my ( $Self, %Param ) = @_;


    # get raw Title and Value strings from field value
#    my $Value = defined $Param{Value} ? $Param{Value} : '';
#    my $Title = $Value;
#
#    # HTMLOuput transformations
#    if ( $Param{HTMLOutput} ) {
#
#        $Value = $Param{LayoutObject}->Ascii2Html(
#            Text           => $Value,
#            HTMLResultMode => 1,
#            Max            => $Param{ValueMaxChars} || '',
#        );
#
#        $Title = $Param{LayoutObject}->Ascii2Html(
#            Text => $Title,
#            Max => $Param{TitleMaxChars} || '',
#        );
#    }
#    else {
#        if ( $Param{ValueMaxChars} && length($Value) > $Param{ValueMaxChars} ) {
#            $Value = substr( $Value, 0, $Param{ValueMaxChars} ) . '...';
#        }
#        if ( $Param{TitleMaxChars} && length($Title) > $Param{TitleMaxChars} ) {
#            $Title = substr( $Title, 0, $Param{TitleMaxChars} ) . '...';
#        }
#    }
#
#    # this field type does not support the Link Feature
#    my $Link;

    my $FieldTree = $Self->EditFieldRender(%Param, 'ReadOnly' => '1');

    # create return structure
    my $Data = {
        Value => '',
        Title => '',
        Link  => '',
        Content => $FieldTree->{Field}
    };

    return $Data;
}

sub IsSortable {
    my ( $Self, %Param ) = @_;

    return 0;
}

sub SearchFieldRender {
    my ( $Self, %Param ) = @_;

    # take config from field config
    my $FieldConfig = $Param{DynamicFieldConfig}->{Config};
    my $FieldName   = 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name};
    my $FieldLabel  = $Param{DynamicFieldConfig}->{Label};

    # set the field value
    my $Value = ( defined $Param{DefaultValue} ? $Param{DefaultValue} : '' );

    # get the field value, this fuction is always called after the profile is loaded
    my $FieldValue = $Self->SearchFieldValueGet(%Param);

    # set values from profile if present
    if ( defined $FieldValue ) {
        $Value = $FieldValue;
    }

    # check and set class if necessary
    my $FieldClass = 'DynamicFieldText';

    my $HTMLString = <<"EOF";
<input type="text" class="$FieldClass" id="$FieldName" name="$FieldName" title="$FieldLabel" value="$Value" />
EOF

    # call EditLabelRender on the common backend
    my $LabelString = $Self->{BackendCommonObject}->EditLabelRender(
        DynamicFieldConfig => $Param{DynamicFieldConfig},
        FieldName          => $FieldName,
    );

    my $Data = {
        Field => $HTMLString,
        Label => $LabelString,
    };

    return $Data;
}

sub SearchFieldValueGet {
    my ( $Self, %Param ) = @_;

    my $Value;

    # get dynamic field value form param object
    if ( defined $Param{ParamObject} ) {
        $Value = $Param{ParamObject}
            ->GetParam( Param => 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name} );
    }

    # otherwise get the value from the profile
    elsif ( defined $Param{Profile} ) {
        $Value = $Param{Profile}->{ 'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name} };
    }
    else {
        return;
    }

    if ( defined $Param{ReturnProfileStructure} && $Param{ReturnProfileStructure} eq 1 ) {
        return {
            'Search_DynamicField_' . $Param{DynamicFieldConfig}->{Name} => $Value,
        };
    }

    return $Value;

}

sub SearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    # get field value
    my $Value = $Self->SearchFieldValueGet(%Param);

    if ( !$Value ) {
        return {
            Parameter => {
                'Like' => '',
            },
            Display => '',
            }
    }

    # return search parameter structure
    return {
        Parameter => {
            'Like' => '*' . $Value . '*',
        },
        Display => $Value,
    };
}

sub _SortedFieldTree {
    my ( $Self, %Param ) = @_;
	my $TreeData = $Self->_FieldTree(
		Class => $Param{Class},
	);
	my @TreeKeys = keys %{$TreeData};
	return \@TreeKeys;
}

sub _FieldTree {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Class)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }
    my $TreeData = {};
    my $FieldIDs = $Self->{FieldTreeObject}->ItemList(
    	Class => $Param{Class},
    );
    
    for my $Key ( keys %{$FieldIDs} ) {
    	$TreeData->{ $Key } = $Self->{FieldTreeObject}->ItemRecursiveName(
	    	ItemID => $Key,
	    );
	}    
    return $TreeData;
}


sub StatsFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    return {
	        Name    => $Param{DynamicFieldConfig}->{Label},
	        Element => 'DynamicField_' . $Param{DynamicFieldConfig}->{Name},
            Values           => $Self->_FieldTree(
					Class => $Self->{ConfigObject}->Get("FieldTree::ProblemTypeClass"),
           		),
        };
}

sub CommonSearchFieldParameterBuild {
    my ( $Self, %Param ) = @_;

    my $Operator = 'Equals';
    my $Value    = $Param{Value};

    return {
        $Operator => $Value,
    };
}

sub ReadableValueRender {
    my ( $Self, %Param ) = @_;

    my $Value = defined $Param{Value} ? $Param{Value} : '';
    
    if ( !$Value || !$Value->{ValueSetID} || $Value->{ValueSetID} =~ /new/i )
    {
        return {};
    }
    
    my $ValueSetID = $Value->{ValueSetID};
    my $FieldTreeID = $Self->{FieldTreeObject}->ValueSetGetFieldTreeID(
        ValueSetID => $ValueSetID
    );
    my $FieldTreeName = $Self->{FieldTreeObject}->ItemRecursiveName(
        ItemID => $FieldTreeID,
    );
    my $FieldIDList = $Self->{FieldTreeObject}->FieldList(
        FieldTreeID => $FieldTreeID,
        Valid => 1,
    );
    my $ValueSet = $Self->{FieldTreeObject}->ValueSetGet(
        ValueSetID => $ValueSetID
    );
    
    my $Content = "";
    $Content .= "Pasirinkta kategorija: " . $FieldTreeName . "\n \n";
    
    for my $FieldID ( keys %{$FieldIDList} ) {
        my $Field = $Self->{FieldTreeObject}->FieldGet(
            FieldID => $FieldID,
        );
        # only include fields that were filled by user
        next if $Field->{FieldType} !~ /(Text|Phone|Money|Integer|Double|Boolean|MultiText|Select|DateTime|EMail)/i;
        my $FieldName = $Field->{FriendlyName} || $Field->{Name} || '( laukas be pavadinimo )';
        my $Value = $ValueSet->{$FieldID};
        if ( $Field->{FieldType} eq 'Select' ) {
            my $ClassList = $Self->{GeneralCatalogObject}->ItemList( Class => $Field->{Template}, Valid => 1);
            $Value = $ClassList->{$Value};
        }
        $Value ||= '-';
        $Content .= "$FieldName: $Value\n";
    }
    $Content .= "\n \n";
    
    # create return structure
    my $Data = {
        Value => $Content,
        Title => 'TITLE',
    };

    return $Data;
}

sub TemplateValueTypeGet {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    # set the field types
    my $EditValueType   = 'SCALAR';
    my $SearchValueType = 'SCALAR';

    # return the correct structure
    if ( $Param{FieldType} eq 'Edit' ) {
        return {
            $FieldName => $EditValueType,
            }
    }
    elsif ( $Param{FieldType} eq 'Search' ) {
        return {
            'Search_' . $FieldName => $SearchValueType,
            }
    }
    else {
        return {
            $FieldName             => $EditValueType,
            'Search_' . $FieldName => $SearchValueType,
            }
    }
}

sub IsAJAXUpdateable {
    my ( $Self, %Param ) = @_;

    return 0;
}

sub RandomValueSet {
    my ( $Self, %Param ) = @_;

    my $Value = int( rand(500) );

    my $Success = $Self->ValueSet(
        %Param,
        Value => $Value,
    );

    if ( !$Success ) {
        return {
            Success => 0,
        };
    }
    return {
        Success => 1,
        Value   => $Value,
    };
}

sub IsMatchable {
    my ( $Self, %Param ) = @_;

    return 1;
}

sub ObjectMatch {
    my ( $Self, %Param ) = @_;

    my $FieldName = 'DynamicField_' . $Param{DynamicFieldConfig}->{Name};

    # return false if not match
    if ( $Param{ObjectAttributes}->{$FieldName} ne $Param{Value} ) {
        return 0;
    }

    return 1;
}

sub AJAXPossibleValuesGet {
    my ( $Self, %Param ) = @_;

    # not supported
    return;
}

sub HistoricalValuesGet {
    my ( $Self, %Param ) = @_;

    # get historical values from database
    my $HistoricalValues = $Self->{DynamicFieldValueObject}->HistoricalValueGet(
        FieldID   => $Param{DynamicFieldConfig}->{ID},
        ValueType => 'Text',
    );

    # retrun the historical values from database
    return $HistoricalValues;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$$

=cut

