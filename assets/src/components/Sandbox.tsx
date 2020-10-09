import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, Popover, TextArea} from './common';
import * as API from '../api';

type State = {
  visible: boolean;
  sending: boolean;
  feedback: string;
};

type Action = {
  type:
    | 'popover/show'
    | 'popover/hide'
    | 'feedback/change'
    | 'popover/show'
    | 'send/start'
    | 'send/done';
  payload?: any;
};

const initial: State = {
  visible: false,
  sending: false,
  feedback: '',
};

const reducer = (state: State, action: Action) => {
  const {type, payload} = action;

  switch (type) {
    case 'popover/show':
      return {...state, visible: true};
    case 'popover/hide':
      return {...state, visible: false};
    case 'feedback/change':
      return {...state, feedback: payload};
    case 'send/start':
      return {...state, sending: true};
    case 'send/done':
      return {...state, sending: false, visible: false, feedback: ''};
    default:
      return state;
  }
};

const FeedbackButton = () => {
  const [state, dispatch] = React.useReducer(reducer, initial);

  const showFeedbackPopover = () => dispatch({type: 'popover/show'});
  const hideFeedbackPopover = () => dispatch({type: 'popover/hide'});
  const handleChangeFeedback = (e: any) =>
    dispatch({type: 'feedback/change', payload: e.target.value});
  const handleSendFeedback = async () => {
    dispatch({type: 'send/start'});

    API.sendProductFeedback(state.feedback)
      .catch((err) => console.error('Error sending feedback:', err))
      .then(() => dispatch({type: 'send/done'}));
  };

  return (
    <Popover
      placement="rightBottom"
      title={null}
      overlayInnerStyle={{padding: 8}}
      visible={state.visible}
      content={
        <Box>
          <TextArea
            placeholder="Send feedback"
            autoFocus
            autoSize={{maxRows: 4, minRows: 2}}
            value={state.feedback}
            onChange={handleChangeFeedback}
          />

          <Flex sx={{mt: 2, justifyContent: 'space-between'}}>
            <Button size="small" onClick={hideFeedbackPopover}>
              Cancel
            </Button>
            <Button
              size="small"
              type="primary"
              loading={state.sending}
              onClick={handleSendFeedback}
            >
              Send
            </Button>
          </Flex>
        </Box>
      }
    >
      <Button onClick={showFeedbackPopover}>Send feedback</Button>
    </Popover>
  );
};

export const Sandbox = () => {
  // Just using this page as a place to hack on UI components before they're ready
  return (
    <Flex p={4} sx={{flex: 1}}>
      <FeedbackButton />
    </Flex>
  );
};

export default Sandbox;
