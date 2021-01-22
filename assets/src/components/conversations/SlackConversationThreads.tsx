import React from 'react';
import {Box, Flex, Image} from 'theme-ui';
import {Text} from '../common';
import Spinner from '../Spinner';
import * as API from '../../api';
import logger from '../../logger';

const SlackConversationThreads = ({
  conversationId,
}: {
  conversationId: string;
}) => {
  const [loading, setLoading] = React.useState(false);
  const [
    slackConversationThreads,
    setSlackConversationThreads,
  ] = React.useState<Array<any>>([]);

  React.useEffect(() => {
    setLoading(true);

    API.fetchSlackConversationThreads(conversationId)
      .then(console.log)
      .catch(console.log);

    API.fetchSlackConversationThreads(conversationId)
      .then((results) => setSlackConversationThreads(results))
      .catch((err) =>
        logger.error('Error retrieving Slack conversation threads:', err)
      )
      .then(() => setLoading(false));
  }, [conversationId]);

  if (loading) {
    return <Spinner size={16} />;
  } else if (!slackConversationThreads || !slackConversationThreads.length) {
    return <Text type="secondary">None</Text>;
  }

  return (
    <Box>
      {slackConversationThreads
        .filter((thread) => thread.permalink && thread.permalink.length > 0)
        .map(({id, permalink}) => {
          return (
            <Flex key={id} mb={1} sx={{alignItems: 'center'}}>
              <Image src="/slack.svg" alt="Slack" sx={{height: 16, mr: 1}} />
              <a href={permalink} target="_blank" rel="noopener noreferrer">
                Link to thread
              </a>
            </Flex>
          );
        })}
    </Box>
  );
};

export default SlackConversationThreads;
