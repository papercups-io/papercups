import React from 'react';
import {Box} from 'theme-ui';
import {TooltipPlacement} from 'antd/lib/tooltip';

import {
  Button,
  Divider,
  Input,
  Modal,
  Select,
  Text,
  TextArea,
  Tooltip,
} from '../common';
import {SendOutlined} from '../icons';
import * as API from '../../api';
import {isValidEmail, formatServerError} from '../../utils';
import {Conversation, ConversationSource} from '../../types';
import logger from '../../logger';

const CONVERSATION_SOURCE_OPTIONS: Array<ConversationSource> = [
  'chat',
  'email',
];
const DEFAULT_CONVERSATION_SOURCE = CONVERSATION_SOURCE_OPTIONS[0];

const NewConversationModal = ({
  customerId,
  visible,
  onCancel,
  onSuccess,
}: {
  customerId: string;
  visible: boolean;
  onCancel: () => void;
  onSuccess: (conversation: Conversation) => void;
}) => {
  const [availableSources, setAvailableSources] = React.useState<
    Array<ConversationSource>
  >(['chat']);
  const [source, setConversationSource] = React.useState<ConversationSource>(
    DEFAULT_CONVERSATION_SOURCE
  );
  const [subject, setSubject] = React.useState('');
  const [message, setMessage] = React.useState('');
  const [isSending, setSending] = React.useState(false);
  const [errorMessage, setErrorMessage] = React.useState<string | null>(null);

  React.useEffect(() => {
    if (visible) {
      Promise.all([
        API.fetchGoogleAuthorization({client: 'gmail'}),
        API.fetchCustomer(customerId, {expand: []}),
      ]).then(([authorization, customer]) => {
        const hasValidAuth = !!(authorization && authorization.id);
        const hasValidCustomerEmail = isValidEmail(customer?.email);
        const canSendEmail = hasValidAuth && hasValidCustomerEmail;

        if (canSendEmail) {
          setAvailableSources(['chat', 'email']);
          setConversationSource('email');
        } else {
          setAvailableSources(['chat']);
        }
      });
    }
  }, [customerId, visible]);

  const handleSendMessage = async () => {
    setSending(true);

    try {
      const conversation = await API.createNewConversation(customerId, {
        source,
        subject,
        message: {
          body: message,
          sent_at: new Date().toISOString(),
        },
      });

      onSuccess(conversation);
    } catch (err) {
      logger.error('Failed to create new conversation:', err);
      const errorMessage = formatServerError(err);
      setErrorMessage(errorMessage);
    }

    setSending(false);
  };

  return (
    <Modal
      title="Start a new conversation"
      visible={visible}
      onCancel={onCancel}
      footer={[
        <Button key="cancel" onClick={onCancel}>
          Cancel
        </Button>,
        <Button
          key="submit"
          type="primary"
          icon={<SendOutlined />}
          loading={isSending}
          onClick={handleSendMessage}
        >
          {isSending ? 'Sending' : 'Send'} as {source}
        </Button>,
      ]}
    >
      <Box>
        <Box>
          {/* TODO: not sure if a select input is the best UX here... */}
          <Select
            id="source"
            style={{width: 240}}
            value={source}
            onChange={setConversationSource}
            options={CONVERSATION_SOURCE_OPTIONS.map((source) => {
              return {
                value: source,
                label: `Send as ${source}`,
                disabled: availableSources.indexOf(source) === -1,
              };
            })}
          />
        </Box>

        <Divider />

        {source === 'email' && (
          <Box mb={3}>
            <Input
              id="subject"
              type="text"
              placeholder="Subject line"
              autoFocus
              value={subject}
              onChange={(e) => setSubject(e.target.value)}
            />
          </Box>
        )}
        <Box mb={3}>
          <TextArea
            id="message"
            placeholder="Enter a message..."
            autoSize={{minRows: 4, maxRows: 6}}
            autoFocus
            value={message}
            onChange={(e) => setMessage(e.target.value)}
          />
        </Box>

        {errorMessage && (
          <Box mb={-3}>
            <Text type="danger">{errorMessage}</Text>
          </Box>
        )}
      </Box>
    </Modal>
  );
};

const ButtonWrapper = ({
  isDisabled = false,
  disabledTooltipPlacement = 'left',
  disabledTooltipTitle = 'This customer already has an open conversation',
  onClick,
}: {
  isDisabled?: boolean;
  disabledTooltipPlacement?: TooltipPlacement;
  disabledTooltipTitle?: string;
  onClick: () => void;
}) => {
  const button = (
    <Button type="primary" onClick={onClick} disabled={isDisabled}>
      Start conversation
    </Button>
  );

  if (isDisabled) {
    return (
      <Tooltip
        title={disabledTooltipTitle}
        placement={disabledTooltipPlacement}
      >
        {button}
      </Tooltip>
    );
  } else {
    return button;
  }
};

export type Props = {
  customerId: string;
  isDisabled?: boolean;
  disabledTooltipPlacement?: TooltipPlacement;
  disabledTooltipTitle?: string;
  onInitializeNewConversation?: (conservation: Conversation) => void;
};

export const StartConversationWrapper = ({
  children,
  customerId,
  onInitializeNewConversation,
}: {
  children: (handleOpenModal: () => void) => React.ReactElement;
  customerId: string;
  onInitializeNewConversation?: (conservation: Conversation) => void;
}) => {
  const [isModalOpen, setModalOpen] = React.useState(false);

  const handleOpenNewConversationModal = () => setModalOpen(true);
  const handleCloseNewConversationModal = () => setModalOpen(false);

  const onSuccess = (conversation: Conversation) => {
    if (typeof onInitializeNewConversation === 'function') {
      onInitializeNewConversation(conversation);
    }

    handleCloseNewConversationModal();
  };

  return (
    <React.Fragment>
      {children(handleOpenNewConversationModal)}

      <NewConversationModal
        customerId={customerId}
        visible={isModalOpen}
        onCancel={handleCloseNewConversationModal}
        onSuccess={onSuccess}
      />
    </React.Fragment>
  );
};

export const StartConversationButton = ({
  customerId,
  isDisabled,
  disabledTooltipPlacement,
  disabledTooltipTitle,
  onInitializeNewConversation,
}: Props) => {
  return (
    <StartConversationWrapper
      customerId={customerId}
      onInitializeNewConversation={onInitializeNewConversation}
    >
      {(onClick) => (
        <ButtonWrapper
          isDisabled={isDisabled}
          disabledTooltipPlacement={disabledTooltipPlacement}
          disabledTooltipTitle={disabledTooltipTitle}
          onClick={onClick}
        />
      )}
    </StartConversationWrapper>
  );
};

export default StartConversationButton;
