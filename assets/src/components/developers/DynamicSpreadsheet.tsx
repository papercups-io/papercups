import React from 'react';
import {Box} from 'theme-ui';
import {isObject} from 'lodash';
import {
  CellValueChangedEvent,
  ColumnApi,
  GridApi,
  GridReadyEvent,
} from 'ag-grid-community';
import {AgGridColumn, AgGridReact} from 'ag-grid-react';

import 'ag-grid-community/dist/styles/ag-grid.css';
// import 'ag-grid-community/dist/styles/ag-theme-alpine.css';
import 'ag-grid-community/dist/styles/ag-theme-balham-dark.css';

export const handleAutoSizeColumns = (api: ColumnApi) => {
  if (!api) {
    return;
  }

  const columns = api.getAllColumns() || [];
  const columnIds = columns.map((col) => col.getId());

  return api.autoSizeColumns(columnIds);
};

const DynamicSpreadsheet = ({
  data,
  includeArrayValues,
  includeObjectValues,
  onUpdate,
}: {
  data: Array<Record<string, any>>;
  includeArrayValues?: boolean;
  includeObjectValues?: boolean;
  onUpdate?: (
    data: Array<Record<string, any>>,
    metadata: {index: number; key: string; value: any}
  ) => void;
}) => {
  const [grid, setGridApis] = React.useState<{
    api: GridApi;
    columnApi: ColumnApi;
  } | null>(null);

  if (!Array.isArray(data)) {
    return null;
  }

  const keys = data.reduce((result, item) => {
    return Object.keys(item).reduce((acc, k) => {
      // Filter out array values
      if (!includeArrayValues && Array.isArray(item[k])) {
        return acc;
      } else if (!includeObjectValues && isObject(item[k])) {
        return acc;
      }

      return {...acc, [k]: true};
    }, result);
  }, {} as {[key: string]: boolean});

  const handleGridReady = (event: GridReadyEvent) => setGridApis(event);

  const handleCellValueChanged = (event: CellValueChangedEvent) => {
    const {rowIndex, data: record, column, value} = event;

    if (!rowIndex) {
      return;
    }

    const key = column.getColId();
    const latest = data.map((row, index) => {
      if (index === rowIndex) {
        return record;
      }

      return row;
    });

    onUpdate && onUpdate(latest, {index: rowIndex, key, value});
  };

  return (
    <Box className="ag-theme-balham-dark" sx={{flex: 1, height: 640}}>
      <AgGridReact
        rowData={data}
        defaultColDef={{
          flex: 1,
          editable: true,
          resizable: true,
          suppressSizeToFit: false,
        }}
        onGridReady={handleGridReady}
        onCellValueChanged={handleCellValueChanged}
        // onGridColumnsChanged={handleAutoSizeColumns}
      >
        {Object.keys(keys).map((key) => {
          return (
            <AgGridColumn
              key={key}
              field={key}
              headerName={key}
              minWidth={200}
            />
          );
        })}
      </AgGridReact>
    </Box>
  );
};

export default DynamicSpreadsheet;
