import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box} from 'theme-ui';
import {TwitterPicker} from 'react-color';
import qs from 'query-string';
import {colors, Input, Paragraph, Title} from '../common';
// Testing widget in separate package
import ChatWidget from '@papercups-io/chat-widget';
import {Button} from '../common';

type Props = RouteComponentProps & {};
type State = {
  color: string;
  title: string;
  subtitle: string;
  accountId: string;
};

class Demo extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    const q = qs.parse(props.location.search) || {};
    const defaultTitle = q.title ? String(q.title).trim() : null;
    const defaultSubtitle = q.subtitle ? String(q.subtitle).trim() : null;
    const defaultColor = q.color ? String(q.color).trim() : null;

    this.state = {
      color: defaultColor || colors.primary,
      title: defaultTitle || 'Welcome to Papercups!',
      subtitle:
        defaultSubtitle || 'Ask us anything in the chat window below 😊',
      accountId: 'eb504736-0f20-4978-98ff-1a82ae60b266',
    };
  }

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
            Hello there! You can customize the widget's display text and colors
          </Paragraph>
        </Box>

        <Box mb={4}>
          <Paragraph>Update the title:</Paragraph>
          <Input
            type="text"
            placeholder="Welcome!"
            value={title}
            onChange={this.handleChangeTitle}
          />
        </Box>

        <Box mb={4}>
          <Paragraph>Update the subtitle:</Paragraph>
          <Input
            type="text"
            placeholder="How can we help you?"
            value={subtitle}
            onChange={this.handleChangeSubtitle}
          />
        </Box>

        <Box mb={4}>
          <Paragraph>
            Try changing the color (hint: you can enter any hex value you want!)
          </Paragraph>
          <TwitterPicker
            color={this.state.color}
            onChangeComplete={this.handleChangeColor}
          />
        </Box>

        <ChatWidget
          title={title || 'Welcome!'}
          subtitle={subtitle}
          primaryColor={color}
          accountId={accountId}
          defaultIsOpen
        />
        <Link to="/register">
          <Button type="primary">Register</Button>
        </Link>
      </Box>
    );
  }
}

export default Demo;
