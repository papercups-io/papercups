import React from 'react';
import {Redirect, RouteComponentProps} from 'react-router';
import qs from 'query-string';
import {parseSlackAuthState} from './support';

export const SlackIntegrationDetails = (props: RouteComponentProps<{}>) => {
  const {type: t, state, ...rest} = qs.parse(props.location.search);
  const key = t || state ? String(t || state) : '';
  const {type, inboxId} = parseSlackAuthState(key);

  if (inboxId && inboxId.length) {
    switch (type) {
      case 'reply':
        return (
          <Redirect
            to={`/inboxes/${inboxId}/integrations/slack/reply?${qs.stringify({
              state,
              ...rest,
            })}`}
          />
        );
      case 'support':
        return (
          <Redirect
            to={`/inboxes/${inboxId}/integrations/slack/support?${qs.stringify({
              state,
              ...rest,
            })}`}
          />
        );
      default:
        return <Redirect to={`/inboxes/${inboxId}/integrations`} />;
    }
  }

  switch (type) {
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
