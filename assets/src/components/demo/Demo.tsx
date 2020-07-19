import React from 'react';
import {Box, Flex} from 'theme-ui';
import {colors, Result} from '../common';
import {SmileOutlined} from '../icons';
// Testing widget in separate package
import ChatWidget from '@papercups-io/chat-widget';
import '@papercups-io/chat-widget/dist/index.css';

type Props = {};
type State = {};

class Demo extends React.Component<Props, State> {
  state: State = {};

  render() {
    return (
      <Flex
        p={6}
        sx={{
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
        }}
      >
        <Box mb={3}>
          <Result
            icon={<SmileOutlined />}
            title="👋 Welcome"
            subTitle="Try out the chat widget below!"
          />
        </Box>

        <ChatWidget
          title="Welcome to Papercups!"
          subtitle="Ask us anything in the chat window below 😊"
          primaryColor={colors.primary}
          accountId="eb504736-0f20-4978-98ff-1a82ae60b266"
        />
      </Flex>
    );
  }
}

export default Demo;
