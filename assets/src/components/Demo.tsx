import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Result} from './common';
import {SmileOutlined} from './icons';
import EmbeddableWidget from './EmbeddableWidget';

type Props = {};
type State = {};

class Demo extends React.Component<Props, State> {
  state: State = {};

  componentDidMount() {
    //
  }

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

        <EmbeddableWidget />
      </Flex>
    );
  }
}

export default Demo;
