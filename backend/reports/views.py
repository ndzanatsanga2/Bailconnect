from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from reports.models import Report
from reports.serializers import ReportCreateSerializer


class ReportCreateView(APIView):
    """Signalement d'une annonce par un utilisateur connecté (spec point 6)."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ReportCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        listing = serializer.validated_data["listing"]

        already_reported = Report.objects.filter(
            listing=listing, reporter=request.user, status=Report.Status.OUVERT
        ).exists()
        if already_reported:
            return Response(
                {"detail": "Vous avez déjà signalé cette annonce."}, status=400
            )

        report = serializer.save(reporter=request.user)
        return Response(ReportCreateSerializer(report).data, status=201)
