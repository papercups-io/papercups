import React from 'react';
import {RouteComponentProps, Link} from 'react-router-dom';
import {Box, Flex} from 'theme-ui';
import request from 'superagent';
import {
  colors,
  notification,
  Alert,
  Button,
  Divider,
  Input,
  Text,
  TextArea,
  Title,
  Tooltip,
} from '../common';
import {DeleteOutlined, RightCircleOutlined} from '../icons';
import {BASE_URL, env} from '../../config';
import * as API from '../../api';
import logger from '../../logger';
import {getBotDemoFaqs, setBotDemoFaqs} from '../../storage';
// Import widget from separate package
import ChatWidget from '@papercups-io/chat-widget';
import {formatUserExternalId} from '../../utils';

const {
  REACT_APP_ADMIN_ACCOUNT_ID = 'eb504736-0f20-4978-98ff-1a82ae60b266',
} = env;

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
    q: 'Do you support live chat?',
    a: 'Yes! Try chatting with us at http://papercups.io :)',
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
  newQuestion: string;
  newAnswer: string;
  hovered: number | null;
};

class Demo extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    this.state = {
      currentUser: null,
      faqs: getBotDemoFaqs() || DEFAULT_FAQS,
      newQuestion: '',
      newAnswer: '',
      hovered: null,
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

    const {email} = currentUser;

    return {
      email: email,
      // TODO: use special external_id here for bot demo?
      external_id: formatUserExternalId(currentUser),
      metadata: {
        ts: +new Date(),
      },
    };
  };

  handleChangeQuestion = (e: React.ChangeEvent<HTMLInputElement>) => {
    this.setState({newQuestion: e.target.value});
  };

  handleChangeAnswer = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    this.setState({newAnswer: e.target.value});
  };

  handleAddNewFaq = (e: any) => {
    e.preventDefault();

    const {newQuestion: q, newAnswer: a} = this.state;

    if (!q || !q.trim().length || !a || !a.trim().length) {
      return notification.error({
        message: 'Error adding training data!',
        description: `Both the question and answer text are required.`,
        placement: 'topLeft',
      });
    }

    this.setState(
      {
        faqs: [{q: q, a: a}, ...this.state.faqs],
        newQuestion: '',
        newAnswer: '',
      },
      () => setBotDemoFaqs(this.state.faqs)
    );

    notification.success({
      message: 'Successfully added training data!',
      description: `Try asking a similar question in the chat window to test it out.`,
      placement: 'topLeft',
      duration: 8,
    });
  };

  handleRemoveQuestion = (index: number) => {
    this.setState(
      {faqs: this.state.faqs.filter((item, idx) => idx !== index)},
      () => setBotDemoFaqs(this.state.faqs)
    );
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
    const {newQuestion, newAnswer, hovered, faqs = []} = this.state;
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
          <Alert
            message={
              <Text>
                This bot is temporarily disabled, click{' '}
                <Link to="/demo">here</Link> to view our standard demo.
              </Text>
            }
            type="error"
            showIcon
          />
        </Box>

        <Divider />

        <Box mb={4}>
          <Title level={4}>Add training data</Title>

          <form onSubmit={this.handleAddNewFaq}>
            <Box mb={3}>
              <label htmlFor="question">New question</label>
              <Input
                id="question"
                type="text"
                placeholder="What is the best open source live chat tool built on Elixir?"
                value={newQuestion}
                onChange={this.handleChangeQuestion}
              />
            </Box>
            <Box mb={3}>
              <label htmlFor="answer">Answer</label>
              <TextArea
                id="answer"
                placeholder="Hmm... it's gotta be Papercups!"
                value={newAnswer}
                onChange={this.handleChangeAnswer}
              />
            </Box>
            <Flex sx={{justifyContent: 'flex-end'}}>
              <Button type="primary" htmlType="submit">
                Add
              </Button>
            </Flex>
          </form>
        </Box>

        <Divider />

        <Title level={2}>Training data</Title>

        <Box mb={4}>
          {faqs.map(({q, a}, key) => {
            const isHovered = key === hovered;

            return (
              <Box
                key={key}
                mb={4}
                onMouseEnter={() => this.setState({hovered: key})}
                onMouseLeave={() => this.setState({hovered: null})}
              >
                <Flex
                  sx={{alignItems: 'baseline', justifyContent: 'space-between'}}
                >
                  <Title level={4}>{q}</Title>

                  {isHovered && (
                    <Tooltip title="Remove question">
                      <Button
                        danger
                        shape="circle"
                        type="link"
                        icon={<DeleteOutlined />}
                        onClick={() => this.handleRemoveQuestion(key)}
                      />
                    </Tooltip>
                  )}
                </Flex>
                <Text>{a}</Text>
              </Box>
            );
          })}
        </Box>

        <Divider />

        <Flex mb={4} sx={{alignItems: 'center'}}>
          <Box mr={3}>
            <Text strong>
              Our chatbot is still in beta at the moment. Sign up at
              papercups.io to be notified of its release
            </Text>
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
          accountId={REACT_APP_ADMIN_ACCOUNT_ID}
          greeting="Hey there! Try asking a question similar to the FAQs to your left :)"
          customer={customer}
          baseUrl={BASE_URL}
          defaultIsOpen
          onChatLoaded={() => logger.debug('Chat loaded!')}
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
