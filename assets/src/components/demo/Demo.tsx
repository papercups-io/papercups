import React from 'react';
import {Box} from 'theme-ui';
import {TwitterPicker} from 'react-color';
import {colors, Input, Paragraph, Title} from '../common';
// Testing widget in separate package
import ChatWidget from '@papercups-io/chat-widget';

type Props = {};
type State = {
  color: string;
  title: string;
  subtitle: string;
  accountId: string;
};

class Demo extends React.Component<Props, State> {
  state: State = {
    color: colors.primary,
    title: 'Welcome to Papercups!',
    subtitle: 'Ask us anything in the chat window below 😊',
    accountId: 'eb504736-0f20-4978-98ff-1a82ae60b266',
  };

  handleChangeTitle = (e: any) => {
    this.setState({title: e.target.value});
  };

  handleChangeSubtitle = (e: any) => {
    this.setState({subtitle: e.target.value});
  };

  handleChangeColor = (color: any) => {
    this.setState({color: color.hex});
  };

  render() {
    const {color, title, subtitle, accountId} = this.state;

    return (
      <Box
        p={5}
        sx={{
          maxWidth: 720,
        }}
      >
        <Box mb={4}>
          <Title>Demo</Title>
          <Paragraph>
            Hello there! You can play around with the chat widget on this page
            by clicking on the toggle in the lower right-hand corner of the
            page.
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Paragraph>Update the title:</Paragraph>
          <Input type="text" value={title} onChange={this.handleChangeTitle} />
        </Box>

        <Box mb={4}>
          <Paragraph>Update the subtitle:</Paragraph>
          <Input
            type="text"
            value={subtitle}
            onChange={this.handleChangeSubtitle}
          />
        </Box>

        <Box mb={4}>
          <Paragraph>Try changing the color:</Paragraph>
          <TwitterPicker
            color={this.state.color}
            onChangeComplete={this.handleChangeColor}
          />
        </Box>

        <ChatWidget
          title={title || 'Welcome'}
          subtitle={subtitle}
          primaryColor={color}
          accountId={accountId}
          defaultIsOpen
        />
      </Box>
    );
  }
}

export default Demo;
