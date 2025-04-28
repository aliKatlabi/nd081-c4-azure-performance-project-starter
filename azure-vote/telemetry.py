import logging
from datetime import datetime
import os 
from opencensus.ext.azure.log_exporter import AzureLogHandler
from opencensus.ext.azure.log_exporter import AzureEventHandler
from opencensus.ext.azure import metrics_exporter
from opencensus.stats import aggregation as aggregation_module
from opencensus.stats import measure as measure_module
from opencensus.stats import stats as stats_module
from opencensus.stats import view as view_module
from opencensus.tags import tag_map as tag_map_module
from opencensus.trace import config_integration
from opencensus.ext.azure.trace_exporter import AzureExporter
from opencensus.trace.samplers import ProbabilitySampler
from opencensus.trace.tracer import Tracer
from opencensus.ext.flask.flask_middleware import FlaskMiddleware
# Custom formatter to handle missing traceId and spanId
class CustomFormatter(logging.Formatter):
    def format(self, record):
        if not hasattr(record, 'traceId'):
            record.traceId = 'N/A'
        if not hasattr(record, 'spanId'):
            record.spanId = 'N/A'
        return super().format(record)

class Telemetry:
    def __init__(self, app):
        self.connection_string = os.getenv('APPINSIGHTS_INSTRUMENTATIONKEY', 'default-key')
        if not self.connection_string:
            raise ValueError("Instrumentation key is not set. Please set the APPINSIGHTS_INSTRUMENTATIONKEY environment variable.")
        # Initialize the Flask app with telemetry
        self.logger = self._initialize_logger()
        self.exporter = self._initialize_exporter()
        self.tracer = self._initialize_tracer()
        self.middleware = self._initialize_middleware(app)

    def _initialize_logger(self):
        
        config_integration.trace_integrations(['logging'])
            # Standard Logging
        logger = logging.getLogger(__name__)
        handler = AzureLogHandler(connection_string=f'{self.connection_string}')
        handler.setFormatter(logging.Formatter('%(traceId)s %(spanId)s %(message)s'))
        logger.addHandler(handler)
            # Set the logging level
        logger.setLevel(logging.INFO)
        return logger
        

    def _initialize_exporter(self):
        # For metrics
        stats = stats_module.stats
        view_manager = stats.view_manager
        exporter = metrics_exporter.new_metrics_exporter(
        enable_standard_metrics=True,
        connection_string=f'{self.connection_string}')
        view_manager.register_exporter(exporter)
        return exporter
        

    def _initialize_tracer(self):
        tracer = Tracer(
                exporter=AzureExporter(connection_string=f'{self.connection_string}'),
                sampler=ProbabilitySampler(1.0)
            )
        return tracer
        
    def _initialize_middleware(self, app):
        
        middleware = FlaskMiddleware(
                app,
                exporter=AzureExporter(connection_string=self.connection_string),
                sampler=ProbabilitySampler(rate=1.0)
            )
        return middleware
    