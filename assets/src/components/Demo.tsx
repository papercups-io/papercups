import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Socket, Channel} from 'phoenix';
import {Result, Button, Input} from './common';
import {SmileOutlined} from './icons';
import EmbeddableWidget from './EmbeddableWidget';

const socket = new Socket('ws://localhost:4000/socket');

type Props = {};
type State = {
  message: string;
  alerts: Array<string>;
};

class Demo extends React.Component<Props, State> {
  state: State = {message: '', alerts: []};

  channel: Channel | null = null;

  componentDidMount() {
    socket.connect();

    this.channel = socket.channel('room:lobby', {});

    this.channel.on('shout', ({message}) => {
      this.setState({alerts: [...this.state.alerts, message]});
    });

    this.channel
      .join()
      .receive('ok', (res) => {
        console.log('Joined successfully', res);
      })
      .receive('error', (err) => {
        console.log('Unable to join', err);
      });
  }

  handleSendMessage = (e: any) => {
    e.preventDefault();
    const {message} = this.state;

    if (!this.channel || !message || message.trim().length === 0) {
      return;
    }

    this.channel.push('shout', {
      message,
      name: 'Test User',
    });

    this.setState({message: ''});
  };

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
        {/* TODO: remove */}
        {false && (
          <Box my={3}>
            <form onSubmit={this.handleSendMessage}>
              <Flex mb={3}>
                <Input
                  type="text"
                  value={this.state.message}
                  onChange={(e) => this.setState({message: e.target.value})}
                />
                <Button htmlType="submit" onClick={this.handleSendMessage}>
                  Send
                </Button>
              </Flex>
            </form>

            {this.state.alerts.map((a, key) => {
              return (
                <Box key={key} my={2}>
                  {a}
                </Box>
              );
            })}
          </Box>
        )}

        <EmbeddableWidget />
      </Flex>
    );
  }
}

export default Demo;
