import {Company} from '../../types';

export const generateSlackChannelUrl = (company: Company) => {
  const {
    slack_channel_id: slackChannelId,
    slack_team_id: slackTeamId,
  } = company;

  if (slackChannelId && slackTeamId) {
    return `https://slack.com/app_redirect?channel=${slackChannelId}&team=${slackTeamId}`;
  } else if (slackChannelId) {
    return `https://slack.com/app_redirect?channel=${slackChannelId}`;
  } else {
    return null;
  }
};
