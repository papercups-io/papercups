import React from 'react';
import {RouteComponentProps} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import qs from 'query-string';
import {colors} from '../common';
import ConversationMessages from './ConversationMessages';
import * as API from '../../api';
import {Conversation, Message} from '../../types';
import logger from '../../logger';

type Props = RouteComponentProps<{}>;
type State = {
  loading: boolean;
  conversation: Conversation | null;
};

class SharedConversationContainer extends React.Component<Props, State> {
  scrollToEl: any = null;

  constructor(props: Props) {
    super(props);

    this.state = {loading: true, conversation: null};
  }

  async componentDidMount() {
    try {
      const {search} = this.props.location;
      const q = qs.parse(search);
      const conversationId = String(q?.cid);
      const token = String(q?.token);
      const conversation = await API.fetchSharedConversation(
        conversationId,
        token
      );

      this.setState({conversation, loading: false}, () =>
        // Slight hack
        setTimeout(() => this.scrollIntoView(), 200)
      );
    } catch (err) {
      logger.error('Unable to fetch shared conversation:', err);

      this.setState({loading: false});
    }
  }

  scrollIntoView = () => {
    this.scrollToEl && this.scrollToEl.scrollIntoView();
  };

  render() {
    const {loading, conversation} = this.state;

    if (!conversation) {
      return null;
    }

    const {customer, messages = []} = conversation;

    return (
      <Flex
        sx={{
          justifyContent: 'center',
          bg: 'rgb(245, 245, 245)',
          border: `1px solid rgba(0,0,0,.06)`,
          boxShadow: 'rgba(0, 0, 0, 0.1) 0px 0px 8px',
          flex: 1,
        }}
      >
        <Box
          py={3}
          sx={{
            width: '100%',
            maxWidth: 640,
            bg: colors.white,
          }}
        >
          <ConversationMessages
            sx={{p: 3}}
            loading={loading}
            messages={messages}
            customer={customer}
            isAgentMessage={(message: Message) => message && !!message.user_id}
            setScrollRef={(el) => (this.scrollToEl = el)}
          />
        </Box>
      </Flex>
    );
  }
}

export default SharedConversationContainer;
