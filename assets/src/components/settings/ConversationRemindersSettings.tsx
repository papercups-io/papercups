import React from 'react';
import {Box, Flex} from 'theme-ui';
import {Button, InputNumber, Switch} from '../common';
import {AccountSettings} from '../../types';

const DEFAULT_REMINDER_HOURS_INTERVAL = 72;
const DEFAULT_MAX_NUM_REMINDERS = 3;

const ConversationRemindersSettings = ({
  settings,
  onSave,
}: {
  settings: AccountSettings;
  onSave: (params: any) => Promise<void>;
}) => {
  const defaultIsEnabled = !!settings?.conversation_reminders_enabled;
  const defaultHoursInterval =
    settings?.conversation_reminder_hours_interval ??
    DEFAULT_REMINDER_HOURS_INTERVAL;
  const defaultMaxNum =
    settings?.max_num_conversation_reminders ?? DEFAULT_MAX_NUM_REMINDERS;

  const [isEditing, setEditing] = React.useState(false);
  const [areRemindersEnabled, setRemindersEnabled] = React.useState(
    defaultIsEnabled
  );
  const [reminderHoursInterval, setReminderHoursInterval] = React.useState(
    defaultHoursInterval
  );
  const [maxNumReminders, setMaxNumReminders] = React.useState(defaultMaxNum);

  const handleStartEditing = () => setEditing(true);

  const handleCancelEditing = () => {
    setEditing(false);
    setRemindersEnabled(defaultIsEnabled);
    setReminderHoursInterval(defaultHoursInterval);
    setMaxNumReminders(defaultMaxNum);
  };

  const handleEnableReminders = async (isEnabled: boolean) => {
    const updates = {
      settings: {...settings, conversation_reminders_enabled: isEnabled},
    };

    return onSave(updates).then(() => setRemindersEnabled(isEnabled));
  };

  const handleUpdateSettings = async () => {
    const updates = {
      settings: {
        ...settings,
        conversation_reminder_hours_interval: reminderHoursInterval,
        max_num_conversation_reminders: maxNumReminders,
      },
    };

    return onSave(updates).then(() => setEditing(false));
  };

  const handleChangeHoursInterval = (value: string | number | undefined) => {
    if (Number.isInteger(value)) {
      setReminderHoursInterval(Number(value));
    }
  };

  const handleChangeMaxReminders = (value: string | number | undefined) => {
    if (Number.isInteger(value)) {
      setMaxNumReminders(Number(value));
    }
  };

  return (
    <Box>
      <Box mb={1}>
        <label htmlFor="conversation_reminders_enabled">
          Enable conversation reminders?
        </label>
      </Box>
      <Box mb={3}>
        <Switch
          checked={areRemindersEnabled}
          onChange={handleEnableReminders}
        />
      </Box>

      <Box mb={3} sx={{maxWidth: 240}}>
        <label htmlFor="conversation_reminder_hours_interval">
          Hours before notifying:
        </label>
        <Box>
          <InputNumber
            id="conversation_reminder_hours_interval"
            value={reminderHoursInterval}
            onChange={handleChangeHoursInterval}
            disabled={!isEditing}
          />
        </Box>
      </Box>

      <Box mb={3} sx={{maxWidth: 240}}>
        <label htmlFor="max_num_conversation_reminders">
          Maximum reminders to send:
        </label>
        <Box>
          <InputNumber
            id="max_num_conversation_reminders"
            value={maxNumReminders}
            onChange={handleChangeMaxReminders}
            disabled={!isEditing}
          />
        </Box>
      </Box>

      {isEditing ? (
        <Flex>
          <Box mr={1}>
            <Button type="default" onClick={handleCancelEditing}>
              Cancel
            </Button>
          </Box>
          <Box>
            <Button type="primary" onClick={handleUpdateSettings}>
              Save
            </Button>
          </Box>
        </Flex>
      ) : (
        <Button type="primary" onClick={handleStartEditing}>
          Edit
        </Button>
      )}
    </Box>
  );
};

export default ConversationRemindersSettings;
