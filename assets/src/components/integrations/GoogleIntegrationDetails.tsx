import React from 'react';
import {Redirect, RouteComponentProps} from 'react-router';
import qs from 'query-string';

export const GoogleIntegrationDetails = (props: RouteComponentProps<{}>) => {
  const {type, state, scope, ...rest} = qs.parse(props.location.search);

  switch (scope) {
    case 'https://www.googleapis.com/auth/gmail.modify':
      return (
        <Redirect
          to={`/integrations/google/gmail?${qs.stringify({
            state,
            scope,
            type,
            ...rest,
          })}`}
        />
      );
    // TODO: still need to set up separate page for sheets once the integration is useful
    case 'https://www.googleapis.com/auth/spreadsheets':
    default:
      return <Redirect to={`/integrations`} />;
  }
};

export default GoogleIntegrationDetails;
