from rest_framework import serializers

from reports.models import Report


class ReportCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Report
        fields = ["id", "listing", "reason", "description", "status", "created_at"]
        read_only_fields = ["id", "status", "created_at"]
