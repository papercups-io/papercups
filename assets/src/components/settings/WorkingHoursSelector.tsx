import React from 'react';
import {Box, Flex} from 'theme-ui';
import {range} from 'lodash';
import {Button, Select} from '../common';
import {WorkingHours, timezones, getDefaultTimezone} from './support';
import logger from '../../logger';

const MINS_IN_A_DAY = 24 * 60;
const DEFAULT_DAY_TYPE = 'everyday';

const DAY_TYPE_OPTIONS = [
  {formatted: 'Every day', value: 'everyday', days: [0, 1, 2, 3, 4, 5, 6]},
  {formatted: 'Weekdays', value: 'weekdays', days: [0, 1, 2, 3, 4]},
  {formatted: 'Weekends', value: 'weekends', days: [5, 6]},
  {formatted: 'Monday', value: 'monday', days: [0]},
  {formatted: 'Tuesday', value: 'tuesday', days: [1]},
  {formatted: 'Wednesday', value: 'wednesday', days: [2]},
  {formatted: 'Thursday', value: 'thursday', days: [3]},
  {formatted: 'Friday', value: 'friday', days: [4]},
  {formatted: 'Saturday', value: 'saturday', days: [5]},
  {formatted: 'Sunday', value: 'sunday', days: [6]},
];

// const DAYS_BY_KEY = {
//   everyday: [0, 1, 2, 3, 4, 5, 6],
//   weekdays: [0, 1, 2, 3, 4],
//   weekends: [5, 6],
//   monday: [0],
//   tuesday: [1],
//   wednesday: [2],
//   thursday: [3],
//   friday: [4],
//   saturday: [5],
//   sunday: [6],
// };

const formatTimeOption = (n: number) => {
  const hour = Math.floor(n / 60);
  const minute = String(n % 60).padStart(2, '0');

  if (hour === 0) {
    return `12:${minute} am`;
  } else if (hour < 12) {
    return `${hour}:${minute} am`;
  } else if (hour === 12) {
    return `12:${minute} pm`;
  } else {
    return `${hour - 12}:${minute} pm`;
  }
};

const generateTimeOptions = () => {
  const interval = 30; // do intervals of 30 mins

  return range(0, MINS_IN_A_DAY, interval)
    .concat(MINS_IN_A_DAY - 1) // include 11:59 pm
    .map((n) => {
      return {value: n, formatted: formatTimeOption(n)};
    });
};

const filterSelectOption = (input: string, option: any) => {
  const label = option && option.label ? String(option.label) : '';
  const sanitized = label.toLowerCase().replace(/_/, ' ');

  return sanitized.indexOf(input.toLowerCase()) >= 0;
};

type Props = {
  timezone?: string | null;
  workingHours: Array<WorkingHours>;
  onCancel?: () => void;
  onSave: (data: {
    time_zone: string;
    working_hours: Array<WorkingHours>;
  }) => Promise<void>;
};

type State = {
  isEditing: boolean;
  selectedTimezone: string;
  selectedDayType: string;
  selectedStartTime: number;
  selectedEndTime: number;
};

class WorkingHoursSelector extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    const [first = {} as WorkingHours] = props.workingHours;

    this.state = {
      isEditing: false,
      selectedTimezone: props.timezone || getDefaultTimezone(),
      selectedDayType: first?.day || DEFAULT_DAY_TYPE,
      selectedStartTime: first?.start_minute || 0,
      selectedEndTime: first?.end_minute || MINS_IN_A_DAY - 1,
    };
  }

  handleResetDefaults = () => {
    const {timezone, workingHours = []} = this.props;
    const [first = {} as WorkingHours] = workingHours;

    this.setState({
      isEditing: false,
      selectedTimezone: timezone || getDefaultTimezone(),
      selectedDayType: first?.day || DEFAULT_DAY_TYPE,
      selectedStartTime: first?.start_minute || 0,
      selectedEndTime: first?.end_minute || MINS_IN_A_DAY - 1,
    });
  };

  handleUpdate = () => {
    const {
      selectedTimezone,
      selectedDayType,
      selectedStartTime,
      selectedEndTime,
    } = this.state;

    // Saving as array because in the near future we will support multiple working hours
    this.props
      .onSave({
        time_zone: selectedTimezone,
        working_hours: [
          {
            day: selectedDayType,
            start_minute: selectedStartTime,
            end_minute: selectedEndTime,
          },
        ],
      })
      .then(() => this.setState({isEditing: false}))
      .catch((err) => {
        logger.error('Error updating working hours:', err);

        this.handleResetDefaults();
      });
  };

  handleStartEditing = () => {
    this.setState({isEditing: true});
  };

  handleSelectTimezone = (selectedTimezone: string) => {
    this.setState({selectedTimezone});
  };

  handleSelectDayType = (selectedDayType: string) => {
    this.setState({selectedDayType});
  };

  handleSelectStartTime = (selectedStartTime: number) => {
    this.setState({selectedStartTime});
  };

  handleSelectEndTime = (selectedEndTime: number) => {
    this.setState({selectedEndTime});
  };

  render() {
    const {
      isEditing,
      selectedTimezone,
      selectedDayType,
      selectedStartTime,
      selectedEndTime,
    } = this.state;

    return (
      <Box>
        <Flex mb={3} sx={{alignItems: 'center'}}>
          <Box mr={2}>
            <label>Default time zone:</label>
          </Box>
          <Select
            showSearch
            style={{width: 280}}
            size="small"
            value={selectedTimezone}
            disabled={!isEditing}
            onChange={this.handleSelectTimezone}
            filterOption={filterSelectOption}
            options={timezones.map(({tzCode, offset}) => {
              return {value: tzCode, label: `(GMT${offset}) ${tzCode}`};
            })}
          />
        </Flex>

        <Flex mx={-2} mb={3} sx={{alignItems: 'center'}}>
          <Box mx={2}>
            <Select
              showSearch
              style={{width: 120}}
              disabled={!isEditing}
              defaultValue={DEFAULT_DAY_TYPE}
              value={selectedDayType}
              onChange={this.handleSelectDayType}
              filterOption={filterSelectOption}
              options={DAY_TYPE_OPTIONS.map(({value, formatted}) => {
                return {value, label: formatted};
              })}
            />
          </Box>

          <Box mx={2}>
            <Select
              showSearch
              style={{width: 120}}
              disabled={!isEditing}
              value={selectedStartTime}
              placeholder="Start time"
              onChange={this.handleSelectStartTime}
              filterOption={filterSelectOption}
              options={generateTimeOptions()
                .slice(0, -1) // start time should not start at end of day
                .map(({value, formatted}) => {
                  return {value, label: formatted};
                })}
            />
          </Box>

          <Box>to</Box>

          <Box mx={2}>
            <Select
              showSearch
              style={{width: 120}}
              disabled={!isEditing}
              value={selectedEndTime}
              placeholder="End time"
              onChange={this.handleSelectEndTime}
              filterOption={filterSelectOption}
              options={generateTimeOptions()
                .filter(({value}) => value > selectedStartTime)
                .map(({value, formatted}) => {
                  return {value, label: formatted};
                })}
            />
          </Box>
        </Flex>
        {isEditing ? (
          <Flex>
            <Box mr={1}>
              <Button type="default" onClick={this.handleResetDefaults}>
                Cancel
              </Button>
            </Box>
            <Box>
              <Button type="primary" onClick={this.handleUpdate}>
                Save
              </Button>
            </Box>
          </Flex>
        ) : (
          <Button type="primary" onClick={this.handleStartEditing}>
            Edit
          </Button>
        )}
      </Box>
    );
  }
}

export default WorkingHoursSelector;
