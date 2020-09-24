import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import request from 'superagent';
import {
  colors,
  Button,
  Divider,
  // Input,
  Paragraph,
  Text,
  Title,
} from '../common';
import {RightCircleOutlined} from '../icons';
import {BASE_URL} from '../../config';
import * as API from '../../api';
import logger from '../../logger';
// Import widget from separate package
import ChatWidget from '@papercups-io/chat-widget';

type FAQ = {
  q: string;
  a: string;
};

const DEFAULT_FAQS: Array<FAQ> = [
  {
    q: 'What is Papercups?',
    a:
      "It's a chat widget that you can embed on your website or mobile app so you can talk with your users :) ",
  },
  {
    q: 'How does Papercups work?',
    a:
      'You can embed our chat widget on your website or mobile app so you can talk with your users :) ',
  },
  {
    q: 'What is the pricing?',
    a: "The first 2 users are free, and it's $40/month for up to 10 users",
  },
  {
    q: 'How much does it cost?',
    a: "The first 2 users are free, and it's $40/month for up to 10 users",
  },
  {
    q: 'Who are you?',
    a: "My name is Alex, I'm one of the co-creators of Papercups :)",
  },
  {
    q: 'Where are you?',
    a: "We're based in New York City",
  },
];

type Props = RouteComponentProps & {};
type State = {
  currentUser?: any;
  faqs: Array<FAQ>;
};

class Demo extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    this.state = {
      currentUser: null,
      faqs: DEFAULT_FAQS,
    };
  }

  componentDidMount() {
    API.me()
      .then((currentUser) => this.setState({currentUser}))
      .catch((err) => {
        // Not logged in, no big deal
      });
  }

  getCustomerMetadata = () => {
    const {currentUser} = this.state;

    if (!currentUser) {
      // TODO: use special external_id here for bot demo?
      return {};
    }

    const {id, email} = currentUser;

    return {
      email: email,
      // TODO: use special external_id here for bot demo?
      external_id: String(id),
      metadata: {
        ts: +new Date(),
      },
    };
  };

  handleNlpDemo = (message: any) => {
    logger.debug('Message sent!', message);

    const {faqs = []} = this.state;

    return request
      .post(`https://papercups-plugin-demo.herokuapp.com/api/demo/nlp`)
      .send({message, faqs})
      .then((res) => res.body.data)
      .then(console.log)
      .catch(console.log);
  };

  render() {
    const {faqs = []} = this.state;
    const customer = this.getCustomerMetadata();

    return (
      <Box
        p={5}
        sx={{
          maxWidth: 640,
        }}
      >
        <Box mb={4}>
          <Title>Papercups Bot Demo</Title>
          <Paragraph>
            Hello! Try asking a question in the chat window.
          </Paragraph>
        </Box>

        <Divider />

        <Box mb={4}>
          {faqs.map(({q, a}, key) => {
            return (
              <Box key={key} mb={4}>
                <Title level={4}>{q}</Title>
                <Text>{a}</Text>
              </Box>
            );
          })}
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
          title="Welcome to Papercups!"
          subtitle="Test out our bot in the chat window below 💭"
          primaryColor={colors.primary}
          accountId="eb504736-0f20-4978-98ff-1a82ae60b266"
          greeting="Hey there! Try asking a question similar to the FAQs to your left :)"
          customer={customer}
          baseUrl={BASE_URL}
          defaultIsOpen
          onChatClosed={() => logger.debug('Chat closed!')}
          onChatOpened={() => logger.debug('Chat opened!')}
          onMessageReceived={(message: any) =>
            logger.debug('Message received!', message)
          }
          onMessageSent={this.handleNlpDemo}
        />
      </Box>
    );
  }
}

export default Demo;
