import React from 'react';
import {Redirect, RouteComponentProps} from 'react-router';
import qs from 'query-string';

export const SlackIntegrationDetails = (props: RouteComponentProps<{}>) => {
  const {type, state, ...rest} = qs.parse(props.location.search);
  const key = type || state ? String(type || state) : null;

  switch (key) {
    case 'reply':
      return (
        <Redirect
          to={`/integrations/slack/reply?${qs.stringify({
            state,
            ...rest,
          })}`}
        />
      );
    case 'support':
      return (
        <Redirect
          to={`/integrations/slack/support?${qs.stringify({
            state,
            ...rest,
          })}`}
        />
      );
    default:
      return <Redirect to={`/integrations`} />;
  }
};

export default SlackIntegrationDetails;
