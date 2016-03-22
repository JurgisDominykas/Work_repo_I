# --
# Kernel/Modules/AdminDynamicFieldText.pm - provides a dynamic fields text config view for admins
# Copyright (C) 2001-2012 OTRS AG, http://otrs.org/
# --
# $Id: AdminDynamicFieldText.pm,v 1.24 2012/04/18 19:38:01 cr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminDynamicFieldFieldTree;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::System::Valid',
    'Kernel::System::CheckItem',
    'Kernel::System::DynamicField',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Web::Request',
    'Kernel::System::Log',
    'Kernel::Config',    
);

use vars qw($VERSION);
$VERSION = qw($Revision: 1.24 $) [1];


sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    # get configured object types
    $Self->{ObjectTypeConfig} = $Kernel::OM->Get('Kernel::Config')->Get('DynamicFields::ObjectType');

    # get the fields config
    $Self->{FieldTypeConfig} = $Kernel::OM->Get('Kernel::Config')->Get('DynamicFields::Driver') || {};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');


    if ( $Self->{Subaction} eq 'Add' ) {
        return $Self->_Add(
            %Param,
        );
    }
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        return $Self->_AddAction(
            %Param,
        );
    }
    if ( $Self->{Subaction} eq 'Change' ) {
        return $Self->_Change(
            %Param,
        );
    }
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        return $Self->_ChangeAction(
            %Param,
        );
    }
    return $LayoutObject->ErrorScreen(
        Message => "Undefined subaction.",
    );
}

sub _Add {
    my ( $Self, %Param ) = @_;
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %GetParam;
    for my $Needed (qw(ObjectType FieldType FieldOrder)) {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed );
        if ( !$Needed ) {
            return $LayoutObject->ErrorScreen(
                Message => "Need $Needed",
            );
        }
    }

    # get the object type and field type display name
    my $ObjectTypeName = $Self->{ObjectTypeConfig}->{ $GetParam{ObjectType} }->{DisplayName} || '';
    my $FieldTypeName  = $Self->{FieldTypeConfig}->{ $GetParam{FieldType} }->{DisplayName}   || '';

    return $Self->_ShowScreen(
        %Param,
        %GetParam,
        Mode           => 'Add',
        ObjectTypeName => $ObjectTypeName,
        FieldTypeName  => $FieldTypeName,
    );
}

sub _AddAction {
    my ( $Self, %Param ) = @_;
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %Errors;
    my %GetParam;

    for my $Needed (qw(Name Label FieldOrder)) {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed );
        if ( !$GetParam{$Needed} ) {
            $Errors{ $Needed . 'ServerError' }        = 'ServerError';
            $Errors{ $Needed . 'ServerErrorMessage' } = 'This field is required.';
        }
    }

    if ( $GetParam{Name} ) {

        # check if name is alphanumeric
        if ( $GetParam{Name} !~ m{\A ( ?: [a-zA-Z] | \d )+ \z}xms ) {

            # add server error error class
            $Errors{NameServerError} = 'ServerError';
            $Errors{NameServerErrorMessage} =
                'The field does not contain only ASCII letters and numbers.';
        }

        # check if name is duplicated
        my %DynamicFieldsList = %{
            $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldList(
                Valid      => 0,
                ResultType => 'HASH',
                )
            };

        %DynamicFieldsList = reverse %DynamicFieldsList;

        if ( $DynamicFieldsList{ $GetParam{Name} } ) {

            # add server error error class
            $Errors{NameServerError}        = 'ServerError';
            $Errors{NameServerErrorMessage} = 'There is another field with the same name.';
        }
    }

    if ( $GetParam{FieldOrder} ) {

        # check if field order is numeric and positive
        if ( $GetParam{FieldOrder} !~ m{\A ( ?: \d )+ \z}xms ) {

            # add server error error class
            $Errors{FieldOrderServerError}        = 'ServerError';
            $Errors{FieldOrderServerErrorMessage} = 'The field must be numeric.';
        }
    }

    for my $ConfigParam (
        qw(ObjectType ObjectTypeName FieldType FieldTypeName DefaultValue ValidID Rows Cols Link)
        )
    {
        $GetParam{$ConfigParam} = $ParamObject->GetParam( Param => $ConfigParam );
    }

    # uncorrectable errors
    if ( !$GetParam{ValidID} ) {
        return $LayoutObject->ErrorScreen(
            Message => "Need ValidID",
        );
    }

    # return to add screen if errors
    if (%Errors) {
        return $Self->_ShowScreen(
            %Param,
            %Errors,
            %GetParam,
            Mode => 'Add',
        );
    }

    # set specific config
    my $FieldConfig = {
        DefaultValue => $GetParam{DefaultValue},
    };

    if ( $GetParam{FieldType} eq 'Text' ) {
        $FieldConfig->{Link} = $GetParam{Link},
    }

    if ( $GetParam{FieldType} eq 'TextArea' ) {
        $FieldConfig->{Rows} = $GetParam{Rows};
        $FieldConfig->{Cols} = $GetParam{Cols};
    }

    # create a new field
    my $FieldID = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldAdd(
        Name       => $GetParam{Name},
        Label      => $GetParam{Label},
        FieldOrder => $GetParam{FieldOrder},
        FieldType  => $GetParam{FieldType},
        ObjectType => $GetParam{ObjectType},
        Config     => $FieldConfig,
        ValidID    => $GetParam{ValidID},
        UserID     => $Self->{UserID},
    );

    if ( !$FieldID ) {
        return $LayoutObject->ErrorScreen(
            Message => "Could not create the new field",
        );
    }

    return $LayoutObject->Redirect(
        OP => "Action=AdminDynamicField",
    );
}

sub _Change {
    my ( $Self, %Param ) = @_;
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %GetParam;
    for my $Needed (qw(ObjectType FieldType)) {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed );
        if ( !$Needed ) {
            return $LayoutObject->ErrorScreen(
                Message => "Need $Needed",
            );
        }
    }

    # get the object type and field type display name
    my $ObjectTypeName = $Self->{ObjectTypeConfig}->{ $GetParam{ObjectType} }->{DisplayName} || '';
    my $FieldTypeName  = $Self->{FieldTypeConfig}->{ $GetParam{FieldType} }->{DisplayName}   || '';

    my $FieldID = $ParamObject->GetParam( Param => 'ID' );

    if ( !$FieldID ) {
        return $LayoutObject->ErrorScreen(
            Message => "Need ID",
        );
    }

    # get dynamic field data
    my $DynamicFieldData = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        ID => $FieldID,
    );

    # check for valid dynamic field configuration
    if ( !IsHashRefWithData($DynamicFieldData) ) {
        return $LayoutObject->ErrorScreen(
            Message => "Could not get data for dynamic field $FieldID",
        );
    }

    my %Config = ();

    # extract configuration
    if ( IsHashRefWithData( $DynamicFieldData->{Config} ) ) {
        %Config = %{ $DynamicFieldData->{Config} };
    }

    return $Self->_ShowScreen(
        %Param,
        %GetParam,
        %${DynamicFieldData},
        %Config,
        ID             => $FieldID,
        Mode           => 'Change',
        ObjectTypeName => $ObjectTypeName,
        FieldTypeName  => $FieldTypeName,
    );
}

sub _ChangeAction {
    my ( $Self, %Param ) = @_;
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    my %Errors;
    my %GetParam;

    for my $Needed (qw(Name Label FieldOrder)) {
        $GetParam{$Needed} = $ParamObject->GetParam( Param => $Needed );
        if ( !$GetParam{$Needed} ) {
            $Errors{ $Needed . 'ServerError' }        = 'ServerError';
            $Errors{ $Needed . 'ServerErrorMessage' } = 'This field is required.';
        }
    }

    my $FieldID = $ParamObject->GetParam( Param => 'ID' );
    if ( !$FieldID ) {
        return $LayoutObject->ErrorScreen(
            Message => "Need ID",
        );
    }

    if ( $GetParam{Name} ) {

        # check if name is lowercase
        if ( $GetParam{Name} !~ m{\A ( ?: [a-zA-Z] | \d )+ \z}xms ) {

            # add server error error class
            $Errors{NameServerError} = 'ServerError';
            $Errors{NameServerErrorMessage} =
                'The field does not contain only ASCII letters and numbers.';
        }

        # check if name is duplicated
        my %DynamicFieldsList = %{
            $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldList(
                Valid      => 0,
                ResultType => 'HASH',
                )
            };

        %DynamicFieldsList = reverse %DynamicFieldsList;

        if (
            $DynamicFieldsList{ $GetParam{Name} } &&
            $DynamicFieldsList{ $GetParam{Name} } ne $FieldID
            )
        {

            # add server error class
            $Errors{NameServerError}        = 'ServerError';
            $Errors{NameServerErrorMessage} = 'There is another field with the same name.';
        }
    }

    if ( $GetParam{FieldOrder} ) {

        # check if field order is numeric and positive
        if ( $GetParam{FieldOrder} !~ m{\A ( ?: \d )+ \z}xms ) {

            # add server error error class
            $Errors{FieldOrderServerError}        = 'ServerError';
            $Errors{FieldOrderServerErrorMessage} = 'The field must be numeric.';
        }
    }

    for my $ConfigParam (
        qw(ObjectType ObjectTypeName FieldType FieldTypeName DefaultValue ValidID Rows Cols Link)
        )
    {
        $GetParam{$ConfigParam} = $ParamObject->GetParam( Param => $ConfigParam );
    }

    # uncorrectable errors
    if ( !$GetParam{ValidID} ) {
        return $LayoutObject->ErrorScreen(
            Message => "Need ValidID",
        );
    }

    # get dynamic field data
    my $DynamicFieldData = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(
        ID => $FieldID,
    );

    # check for valid dynamic field configuration
    if ( !IsHashRefWithData($DynamicFieldData) ) {
        return $LayoutObject->ErrorScreen(
            Message => "Could not get data for dynamic field $FieldID",
        );
    }

    # only for textarea
    if ( $GetParam{FieldType} eq 'TextArea' ) {
        if ( $GetParam{Rows} ) {

            # check if field order is numeric and positive
            if ( $GetParam{Rows} !~ m{\A ( ?: \d )+ \z}xms ) {

                # add server error error class
                $Errors{RowsServerError}        = 'ServerError';
                $Errors{RowsServerErrorMessage} = 'The field must be numeric.';
            }
        }
        if ( $GetParam{Cols} ) {

            # check if field order is numeric and positive
            if ( $GetParam{Cols} !~ m{\A ( ?: \d )+ \z}xms ) {

                # add server error error class
                $Errors{ColsServerError}        = 'ServerError';
                $Errors{ColsServerErrorMessage} = 'The field must be numeric.';
            }
        }
    }

    # return to change screen if errors
    if (%Errors) {
        return $Self->_ShowScreen(
            %Param,
            %Errors,
            %GetParam,
            ID   => $FieldID,
            Mode => 'Change',
        );
    }

    # set specific config
    my $FieldConfig = {
        DefaultValue => $GetParam{DefaultValue},
    };

    if ( $GetParam{FieldType} eq 'Text' ) {
        $FieldConfig->{Link} = $GetParam{Link};
    }

    if ( $GetParam{FieldType} eq 'TextArea' ) {
        $FieldConfig->{Rows} = $GetParam{Rows};
        $FieldConfig->{Cols} = $GetParam{Cols};
    }

    # update dynamic field (FieldType and ObjectType cannot be changed; use old values)
    my $UpdateSuccess = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldUpdate(
        ID         => $FieldID,
        Name       => $GetParam{Name},
        Label      => $GetParam{Label},
        FieldOrder => $GetParam{FieldOrder},
        FieldType  => $DynamicFieldData->{FieldType},
        ObjectType => $DynamicFieldData->{ObjectType},
        Config     => $FieldConfig,
        ValidID    => $GetParam{ValidID},
        UserID     => $Self->{UserID},
    );

    if ( !$UpdateSuccess ) {
        return $LayoutObject->ErrorScreen(
            Message => "Could not update the field $GetParam{Name}",
        );
    }

    return $LayoutObject->Redirect(
        OP => "Action=AdminDynamicField",
    );
}

sub _ShowScreen {
    my ( $Self, %Param ) = @_;
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    $Param{DisplayFieldName} = 'New';

    if ( $Param{Mode} eq 'Change' ) {
        $Param{ShowWarning}      = 'ShowWarning';
        $Param{DisplayFieldName} = $Param{Name};
    }

    # header
    my $Output = $LayoutObject->Header();
    $Output .= $LayoutObject->NavigationBar();

    # get all fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    # get the list of order numbers (is already sorted).
    my @DynamicfieldOrderList;
    for my $Dynamicfield ( @{$DynamicFieldList} ) {
        push @DynamicfieldOrderList, $Dynamicfield->{FieldOrder};
    }

    # when adding we need to create an extra order number for the new field
    if ( $Param{Mode} eq 'Add' ) {

        # get the last element form the order list and add 1
        my $LastOrderNumber = $DynamicfieldOrderList[-1];
        $LastOrderNumber++;

        # add this new order number to the end of the list
        push @DynamicfieldOrderList, $LastOrderNumber;
    }

    my $DynamicFieldOrderSrtg = $LayoutObject->BuildSelection(
        Data          => \@DynamicfieldOrderList,
        Name          => 'FieldOrder',
        SelectedValue => $Param{FieldOrder} || 1,
        PossibleNone  => 0,
        Class         => 'W50pc Validate_Number',
    );

    my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();

    # create the Validity select
    my $ValidityStrg = $LayoutObject->BuildSelection(
        Data         => \%ValidList,
        Name         => 'ValidID',
        SelectedID   => $Param{ValidID} || 1,
        PossibleNone => 0,
        Translation  => 1,
        Class        => 'W50pc',
    );

    # define config field specific settings
    my $DefaultValue = ( defined $Param{DefaultValue} ? $Param{DefaultValue} : '' );

    # create the default value element
    $LayoutObject->Block(
        Name => 'DefaultValue' . $Param{FieldType},
        Data => {
            %Param,
            DefaultValue => $DefaultValue,
        },
    );

    # define config field specific settings
    my $Link = $Param{Link} || '';

    if ( $Param{FieldType} eq 'Text' ) {

        # create the default link element
        $LayoutObject->Block(
            Name => 'Link',
            Data => {
                %Param,
                Link => $Link,
            },
        );
    }

    if ( $Param{FieldType} eq 'TextArea' ) {

        # create the default value element
        $LayoutObject->Block(
            Name => 'ColsRowsValues',
            Data => {
                %Param,
                Rows => $Param{Rows},
                Cols => $Param{Cols},
            },
        );
    }

    # generate output
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminDynamicFieldText',
        Data         => {
            %Param,
            ValidityStrg          => $ValidityStrg,
            DynamicFieldOrderSrtg => $DynamicFieldOrderSrtg,
            DefaultValue          => $DefaultValue,
            Link                  => $Link,
            }
    );

    $Output .= $LayoutObject->Footer();

    return $Output;
}
1;
