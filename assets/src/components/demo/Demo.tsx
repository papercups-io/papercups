import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import {TwitterPicker} from 'react-color';
import qs from 'query-string';
import {
  colors,
  Button,
  Divider,
  Input,
  Paragraph,
  Text,
  Title,
} from '../common';
import {RightCircleOutlined} from '../icons';
import {BASE_URL, env, isDev, isStorytimeEnabled} from '../../config';
import * as API from '../../api';
import logger from '../../logger';
// Testing widget in separate package
// import {Storytime} from '../../lib/storytime'; // For testing
import {Storytime} from '@papercups-io/storytime';
import ChatWidget from '@papercups-io/chat-widget';
import {formatUserExternalId} from '../../utils';

const {
  REACT_APP_ADMIN_ACCOUNT_ID = 'eb504736-0f20-4978-98ff-1a82ae60b266',
} = env;

type Props = RouteComponentProps & {};
type State = {
  color: string;
  title: string;
  subtitle: string;
  accountId: string;
  currentUser?: any;
};

class Demo extends React.Component<Props, State> {
  storytime: Storytime | null = null;

  constructor(props: Props) {
    super(props);

    const q = qs.parse(props.location.search) || {};
    const defaultTitle = q.title ? String(q.title).trim() : null;
    const defaultSubtitle = q.subtitle ? String(q.subtitle).trim() : null;
    const defaultColor = q.color ? String(q.color).trim() : null;

    this.state = {
      color: defaultColor || colors.primary,
      title: defaultTitle || 'Welcome to Papercups!',
      subtitle: defaultSubtitle || 'Ask us anything using the chat window 💭',
      accountId: REACT_APP_ADMIN_ACCOUNT_ID,
      currentUser: null,
    };
  }

  componentDidMount() {
    API.me()
      .then((currentUser) => this.setState({currentUser}))
      .catch((err) => {
        // Not logged in, no big deal
      })
      .then(() => {
        if (isStorytimeEnabled) {
          this.storytime = Storytime.init({
            accountId: this.state.accountId,
            baseUrl: BASE_URL,
            customer: this.getCustomerMetadata(),
            debug: isDev,
          });
        }
      })
      .catch((err) => {
        logger.error('Error setting up Storytime!', err);
      });
  }

  componentWillUnmount() {
    this.storytime && this.storytime.finish();
  }

  handleChangeTitle = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({title: e.target.value});
  };

  handleChangeSubtitle = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({subtitle: e.target.value});
  };

  handleChangeColor = (color: any) => {
    this.setState({color: color.hex});
  };

  getCustomerMetadata = () => {
    const {currentUser} = this.state;

    if (!currentUser) {
      return {};
    }

    const {email} = currentUser;

    // TODO: include name if available
    return {
      email: email,
      external_id: formatUserExternalId(currentUser),
      metadata: {
        // Just testing that ad hoc metadata works :)
        ts: +new Date(),
      },
    };
  };

  render() {
    const {color, title, subtitle, accountId} = this.state;
    const customer = this.getCustomerMetadata();
    const defaultColors = [
      colors.primary,
      '#00B3BE',
      '#099720',
      '#7556EB',
      '#DE2828',
      '#F223C5',
      '#EC7F00',
      '#1E1F21',
      '#89603A',
      '#878784',
    ];

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
            Hello! Try customizing the chat widget's display text and colors.
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
            Try changing the color (you can enter any hex value you want!)
          </Paragraph>
          <TwitterPicker
            color={this.state.color}
            colors={defaultColors}
            onChangeComplete={this.handleChangeColor}
          />
        </Box>

        <Divider />

        <Flex mb={4} sx={{alignItems: 'center'}}>
          <Box mr={3}>
            <Text strong>Ready to get started?</Text>
          </Box>
          <Link to="/register">
            <Button type="primary" icon={<RightCircleOutlined />}>
              Sign up for free
            </Button>
          </Link>
        </Flex>

        <ChatWidget
          title={title || 'Welcome!'}
          subtitle={subtitle}
          primaryColor={color}
          accountId={accountId}
          greeting="Hello :) have any questions or feedback? Alex or Kam will reply as soon as they can! In the meantime, come join our community [Slack](https://join.slack.com/t/papercups-io/shared_invite/zt-h0c3fxmd-hZi1Zp8~D61S6GD16aMqmg)."
          customer={customer}
          baseUrl={BASE_URL}
          iconVariant="filled"
          defaultIsOpen
          showAgentAvailability
          onChatLoaded={() => logger.debug('Chat loaded!')}
          onChatClosed={() => logger.debug('Chat closed!')}
          onChatOpened={() => logger.debug('Chat opened!')}
          onMessageReceived={(message: any) =>
            logger.debug('Message received!', message)
          }
          onMessageSent={(message: any) =>
            logger.debug('Message sent!', message)
          }
        />
      </Box>
    );
  }
}

export default Demo;
